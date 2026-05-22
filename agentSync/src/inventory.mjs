import cp from "node:child_process";
import fs from "node:fs";
import fsp from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { exists, readJson, resolvePath, walk } from "./fs-utils.mjs";
import { overlayPath } from "./overlay.mjs";

function asRel(file) {
  return file.replace(process.env.HOME || "", "~");
}

async function listEntries(dir) {
  if (!exists(dir)) return [];
  const entries = await fsp.readdir(dir, { withFileTypes: true });
  return entries.map((entry) => path.join(dir, entry.name)).sort();
}

function linkTarget(file) {
  try {
    return fs.lstatSync(file).isSymbolicLink() ? fs.readlinkSync(file) : undefined;
  } catch {
    return undefined;
  }
}

function classifyManagedPath(file, manifest) {
  const target = manifest.links?.[file];
  if (!target) return undefined;
  return { path: file, target, kind: "manifest-link" };
}

async function scanProjectClaudeSettings(searchRoots) {
  const results = [];
  const skip = new Set([".git", "node_modules", "vendor", "dist", "build", ".next", "target", "telemetry", "file-history"]);
  for (const root of searchRoots) {
    if (!exists(root)) continue;
    const files = await walk(
      root,
      (full) => /(^|\/)\.claude\/settings(\.local)?\.json$/.test(full),
      { maxDepth: 5, skipDir: (_full, name) => skip.has(name) },
    );
    results.push(...files);
  }
  return [...new Set(results)].sort();
}

function summarizeJsonObject(obj) {
  if (!obj || typeof obj !== "object") return undefined;
  return Object.keys(obj).sort();
}

function npmRootGlobal() {
  try {
    return cp.execFileSync("npm", ["root", "-g"], { encoding: "utf8" }).trim();
  } catch {
    return "/opt/homebrew/lib/node_modules";
  }
}

function parseNpmPackageName(source) {
  let spec = source.replace(/^npm:/, "");
  if (spec.startsWith("@")) {
    const parts = spec.split("/");
    if (parts.length < 2) return spec;
    const second = parts[1].replace(/@[^@/]+$/, "");
    return `${parts[0]}/${second}`;
  }
  return spec.replace(/@[^@/]+$/, "");
}

function resolvePiPackageRoot(source, cfg) {
  const piDir = path.dirname(cfg.pi.settingsPath);
  if (source.startsWith("npm:")) return path.join(npmRootGlobal(), parseNpmPackageName(source));
  if (source.startsWith("git:github.com/")) return path.join(piDir, "git", "github.com", source.slice("git:github.com/".length).replace(/@[^/]+$/, ""));
  if (source.startsWith("https://github.com/")) return path.join(piDir, "git", "github.com", source.slice("https://github.com/".length).replace(/@[^/]+$/, ""));
  if (!/^(git:|https?:|ssh:|npm:)/.test(source)) return resolvePath(source, piDir);
  return undefined;
}

function packageFilterState(relPath, filters) {
  if (!Array.isArray(filters)) return "enabled";
  if (filters.length === 0) return "disabled";
  const norm = relPath.replace(/^\.\//, "");
  let enabled = !filters.some((f) => !f.startsWith("-") && !f.startsWith("!") && !f.startsWith("+"));
  for (const raw of filters) {
    const negative = raw.startsWith("-") || raw.startsWith("!");
    const positive = raw.startsWith("+");
    const clean = raw.replace(/^[!+-]/, "").replace(/^\.\//, "");
    const matches = norm === clean || norm.startsWith(`${clean}/`) || clean === path.basename(norm);
    if (!matches) continue;
    if (negative) enabled = false;
    else if (positive || !negative) enabled = true;
  }
  return enabled ? "enabled" : "disabled";
}

async function collectPiPackageInventory(cfg) {
  const settings = await readJson(cfg.pi.settingsPath, {});
  const packages = [];
  for (const entry of settings.packages || []) {
    const source = typeof entry === "string" ? entry : entry?.source;
    if (!source) continue;
    const root = resolvePiPackageRoot(source, cfg);
    const pkgJson = root ? await readJson(path.join(root, "package.json"), {}) : {};
    const pi = pkgJson.pi || {};
    const resources = [];
    for (const type of ["extensions", "skills", "prompts", "themes"]) {
      for (const item of pi[type] || []) {
        const rel = String(item).replace(/^\.\//, "");
        resources.push({ type, path: item, state: packageFilterState(rel, typeof entry === "object" ? entry[type] : undefined) });
      }
    }
    packages.push({ source, root, name: pkgJson.name, version: pkgJson.version, description: pkgJson.description, resources });
  }

  const directExtensions = [];
  const extDir = path.join(cfg.pi.agentDir, "extensions");
  for (const file of await listEntries(extDir)) {
    if (/\.(ts|js)$/.test(file) || file.endsWith("index.ts") || file.endsWith("index.js")) {
      directExtensions.push(file);
    }
  }

  return { settingsPath: cfg.pi.settingsPath, packages, directExtensions };
}

export async function buildInventory(cfg, { projectRoots = [] } = {}) {
  const manifest = await readJson(cfg.manifestPath, { links: {}, skills: [], commands: [] });
  const claudeSettings = await readJson(cfg.claude.settingsPath, {});
  const claudeJsonPath = path.join(path.dirname(cfg.claude.dir), ".claude.json");
  const claudeJson = await readJson(claudeJsonPath, {});

  const managed = [];
  const unmanaged = [];
  const ignored = [];
  const missing = [];

  for (const [file, target] of Object.entries(manifest.links || {})) {
    const present = exists(file);
    const currentTarget = present ? linkTarget(file) : undefined;
    managed.push({ path: file, target, present, currentTarget });
    if (!present) missing.push({ path: file, target, reason: "managed path missing" });
  }

  const managedSet = new Set(Object.keys(manifest.links || {}));

  for (const dirName of ["skills", "commands"]) {
    const dir = path.join(cfg.claude.dir, dirName);
    for (const item of await listEntries(dir)) {
      if (managedSet.has(item)) continue;
      unmanaged.push({ type: dirName.slice(0, -1), path: item, target: linkTarget(item), reason: "not in manifest" });
    }
  }

  const pluginsDir = path.join(cfg.claude.dir, "plugins");
  const pluginImportant = [
    path.join(pluginsDir, "blocklist.json"),
    path.join(pluginsDir, "claude-hud", "config.json"),
  ];
  for (const file of pluginImportant) {
    if (exists(file)) unmanaged.push({ type: "plugin-config", path: file, reason: "plugin config file not managed" });
  }
  for (const dir of await listEntries(path.join(pluginsDir, "marketplaces"))) {
    unmanaged.push({ type: "plugin-marketplace", path: dir, reason: "plugin marketplace checkout not managed" });
  }
  for (const dir of await listEntries(path.join(pluginsDir, "data"))) {
    unmanaged.push({ type: "plugin-data", path: dir, reason: "plugin data not managed" });
  }

  const hooksDir = path.join(cfg.claude.dir, "hooks");
  for (const dir of await listEntries(hooksDir)) {
    unmanaged.push({ type: "hook-files", path: dir, reason: "hook implementation files not managed" });
  }

  if (Object.keys(claudeJson.mcpServers || {}).length > 0) {
    unmanaged.push({ type: "mcpServers", path: claudeJsonPath, keys: summarizeJsonObject(claudeJson.mcpServers), reason: "~/.claude.json mcpServers not managed" });
  }
  if (Object.keys(claudeJson.projects || {}).length > 0) {
    unmanaged.push({ type: "project-state", path: claudeJsonPath, count: Object.keys(claudeJson.projects).length, reason: "Claude project trust/metrics state not managed" });
  }
  for (const file of await scanProjectClaudeSettings(projectRoots)) {
    unmanaged.push({ type: "project-settings", path: file, reason: "project .claude settings not managed" });
  }

  const overlay = await readJson(overlayPath(cfg), {});
  const settingsManagedKeys = ["agentSync", "permissions", "hooks", "enabledPlugins", "extraKnownMarketplaces", "skipDangerousModePermissionPrompt"];
  const providerKeys = Object.keys(claudeSettings.env || {}).filter((key) => (cfg.providerSwitch.envKeyPrefixes || []).some((prefix) => key.startsWith(prefix)));

  for (const name of ["projects", "sessions", "tasks", "session-env", "paste-cache", "file-history", "history.jsonl", "telemetry", "cache", "shell-snapshots", "backups"]) {
    const p = path.join(cfg.claude.dir, name);
    if (exists(p)) ignored.push({ path: p, reason: "Claude runtime/cache/history" });
  }

  const piInventory = await collectPiPackageInventory(cfg);

  return {
    managed,
    unmanaged,
    missing,
    ignored,
    pi: piInventory,
    settings: {
      path: cfg.claude.settingsPath,
      providerEnvKeys: providerKeys.sort(),
      overlayPath: overlayPath(cfg),
      overlayKeys: Object.keys(overlay).sort(),
      managedOrProtectedKeys: settingsManagedKeys.filter((key) => claudeSettings[key] !== undefined),
      otherTopLevelKeys: Object.keys(claudeSettings).filter((key) => !settingsManagedKeys.includes(key) && key !== "env").sort(),
    },
    claudeJson: {
      path: claudeJsonPath,
      mcpServers: summarizeJsonObject(claudeJson.mcpServers || {}),
      projectCount: Object.keys(claudeJson.projects || {}).length,
      topLevelKeys: Object.keys(claudeJson).sort(),
    },
  };
}

export function printInventory(inv) {
  const printSection = (title, rows, formatter) => {
    console.log(`\n## ${title} (${rows.length})`);
    if (rows.length === 0) {
      console.log("- <none>");
      return;
    }
    for (const row of rows) console.log(formatter(row));
  };

  printSection("Managed", inv.managed, (row) => `- ${asRel(row.path)} -> ${asRel(row.target)}${row.present ? "" : " [missing]"}`);
  printSection("Known but unmanaged", inv.unmanaged, (row) => {
    const extra = row.keys ? ` keys=${row.keys.join(",")}` : row.count !== undefined ? ` count=${row.count}` : row.target ? ` -> ${asRel(row.target)}` : "";
    return `- [${row.type}] ${asRel(row.path)}${extra} — ${row.reason}`;
  });
  printSection("Missing managed paths", inv.missing, (row) => `- ${asRel(row.path)} -> ${asRel(row.target)} — ${row.reason}`);
  printSection("Ignored runtime/cache", inv.ignored, (row) => `- ${asRel(row.path)} — ${row.reason}`);

  console.log(`\n## Pi-only capabilities (report only, not synced to Claude) (${inv.pi.packages.length})`);
  for (const pkg of inv.pi.packages) {
    console.log(`- ${pkg.source}${pkg.name ? ` (${pkg.name}@${pkg.version || "?"})` : ""}${pkg.root ? ` root=${asRel(pkg.root)}` : ""}`);
    if (pkg.description) console.log(`  desc: ${pkg.description}`);
    for (const res of pkg.resources) console.log(`  - [${res.state} in Pi] ${res.type}: ${res.path}`);
  }
  if (inv.pi.directExtensions.length) {
    console.log(`\n## Pi direct extensions (${inv.pi.directExtensions.length})`);
    for (const file of inv.pi.directExtensions) console.log(`- ${asRel(file)}`);
  }

  console.log("\n## Settings summary");
  console.log(`- settings: ${asRel(inv.settings.path)}`);
  console.log(`- provider env keys: ${inv.settings.providerEnvKeys.join(", ") || "<none>"}`);
  console.log(`- overlay: ${asRel(inv.settings.overlayPath)} keys=${inv.settings.overlayKeys.join(",") || "<none>"}`);
  console.log(`- protected settings keys: ${inv.settings.managedOrProtectedKeys.join(", ") || "<none>"}`);
  console.log(`- other settings keys: ${inv.settings.otherTopLevelKeys.join(", ") || "<none>"}`);
  console.log(`- ~/.claude.json mcpServers: ${inv.claudeJson.mcpServers.join(", ") || "<none>"}; projects=${inv.claudeJson.projectCount}`);
}
