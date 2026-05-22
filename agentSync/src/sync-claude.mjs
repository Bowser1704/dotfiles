import cp from "node:child_process";
import fsp from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";
import {
  backupFileIfExists,
  exists,
  readJson,
  replaceWithSymlink,
  removeManagedLink,
  walk,
  writeJson,
} from "./fs-utils.mjs";
import { PROJECT_ROOT } from "./config.mjs";
import { discoverResources } from "./resources.mjs";
import { loadClaudeSettings, mergeClaudeSettingsForSync, writeClaudeSettingsIfChanged } from "./claude-settings.mjs";
import { applyClaudeOverlay, loadClaudeOverlay } from "./overlay.mjs";

const execFile = promisify(cp.execFile);

function isManagedClaudePath(linkPath, cfg) {
  return linkPath.startsWith(path.join(cfg.claude.dir, "skills") + path.sep)
    || linkPath.startsWith(path.join(cfg.claude.dir, "commands") + path.sep);
}

async function cleanupStaleClaudeLinks(previousLinks, desiredLinks, cfg, opts) {
  for (const [link, target] of Object.entries(previousLinks || {})) {
    if (!isManagedClaudePath(link, cfg)) continue;
    if (desiredLinks[link] === target) continue;
    const removed = await removeManagedLink(link, target, opts);
    if (removed) opts.log(`removed stale managed link ${link}`);
  }
}

async function deployClaudeConfigs(cfg, opts) {
  const { dryRun = false, log = () => {} } = opts;
  const configsDir = cfg.claude.configsDir;
  if (!configsDir || !exists(configsDir)) return [];

  const files = await walk(configsDir, () => true, {
    skipDir: (_full, name) => name === ".git" || name === "node_modules",
  });

  const deployed = [];
  for (const srcFile of files.sort()) {
    const relPath = path.relative(configsDir, srcFile);
    if (relPath === "overlay.json") continue;
    const dstFile = path.join(cfg.claude.dir, relPath);

    const srcContent = await fsp.readFile(srcFile, "utf8");
    let dstContent;
    try {
      dstContent = await fsp.readFile(dstFile, "utf8");
    } catch { dstContent = undefined; }

    if (srcContent === dstContent) continue;

    if (dstContent !== undefined) {
      await backupFileIfExists(dstFile, { dryRun, log });
    }
    if (dryRun) {
      log(`dry-run: deploy ${relPath} -> ${dstFile}`);
    } else {
      await fsp.mkdir(path.dirname(dstFile), { recursive: true });
      await fsp.writeFile(dstFile, srcContent, "utf8");
    }
    log(`deployed ${relPath}`);
    deployed.push(relPath);
  }
  return deployed;
}

async function ensureSkillDeps(cfg, opts) {
  const { dryRun = false, log = () => {} } = opts;
  const allDirs = [...(cfg.resources.skillDirs || []), ...(cfg.resources.extraSkillDirs || [])];
  for (const dir of allDirs) {
    const pkg = path.join(dir, "package.json");
    const nm = path.join(dir, "node_modules");
    if (!exists(pkg) || exists(nm)) continue;
    if (dryRun) {
      log(`dry-run: npm install in ${dir}`);
      continue;
    }
    log(`installing skill dependencies in ${dir}...`);
    await execFile("npm", ["install", "--omit=dev"], { cwd: dir });
    log(`  done`);
  }
}

// NOTE: agent-sync does NOT manage CLAUDE.md or AGENTS.md.
// Those files are user-owned and edited directly — never symlink or overwrite them.
export async function syncClaude(cfg, previous, opts = {}) {
  const { dryRun = false, log = () => {}, warn = () => {} } = opts;
  await ensureSkillDeps(cfg, opts);
  const resources = await discoverResources(cfg);
  const managedLinks = {};

  {
    const skillsDir = path.join(cfg.claude.dir, "skills");
    await fsp.mkdir(skillsDir, { recursive: true });
    for (const skill of [...resources.skills.values()].sort((a, b) => a.name.localeCompare(b.name))) {
      const link = path.join(skillsDir, skill.name);
      const force = previous.links?.[link] === skill.dir;
      const result = await replaceWithSymlink(link, skill.dir, { force, dryRun, log });
      if (result.skipped) {
        warn(`preserved Claude skill ${link}: ${result.reason}`);
        continue;
      }
      if (result.changed) log(`linked Claude skill ${skill.name} -> ${skill.dir}`);
      managedLinks[link] = skill.dir;
    }
  }

  {
    const commandsDir = path.join(cfg.claude.dir, "commands");
    await fsp.mkdir(commandsDir, { recursive: true });
    for (const prompt of [...resources.prompts.values()].sort((a, b) => a.name.localeCompare(b.name))) {
      const link = path.join(commandsDir, `${prompt.name}.md`);
      const force = previous.links?.[link] === prompt.file;
      const result = await replaceWithSymlink(link, prompt.file, { force, dryRun, log });
      if (result.skipped) {
        warn(`preserved Claude command ${link}: ${result.reason}`);
        continue;
      }
      if (result.changed) log(`linked Claude command /${prompt.name} -> ${prompt.file}`);
      managedLinks[link] = prompt.file;
    }
  }

  await cleanupStaleClaudeLinks(previous.links || {}, managedLinks, cfg, { dryRun, log });

  const settingsBefore = await loadClaudeSettings(cfg);
  const settingsAfter = JSON.parse(JSON.stringify(settingsBefore));
  applyClaudeOverlay(settingsAfter, await loadClaudeOverlay(cfg));
  mergeClaudeSettingsForSync(settingsAfter, cfg, resources);
  await writeClaudeSettingsIfChanged(cfg.claude.settingsPath, settingsBefore, settingsAfter, { dryRun, log });

  const deployed = await deployClaudeConfigs(cfg, { dryRun, log });

  return {
    managedLinks,
    skills: [...resources.skills.keys()].sort(),
    commands: [...resources.prompts.keys()].sort(),
    deployedConfigs: deployed,
  };
}
