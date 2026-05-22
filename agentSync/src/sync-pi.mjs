import fsp from "node:fs/promises";
import path from "node:path";
import {
  exists,
  readJson,
  replaceWithSymlink,
  removeManagedLink,
  writeJson,
} from "./fs-utils.mjs";
import { PROJECT_ROOT } from "./config.mjs";

function piPackageRoot() {
  return path.join(PROJECT_ROOT, "..", "pi");
}

async function ensurePiSettings(cfg, opts) {
  const { dryRun = false, log = () => {} } = opts;
  const piPkgRoot = piPackageRoot();
  const settingsPath = cfg.pi.settingsPath;
  const templatePath = path.join(piPkgRoot, "settings.template.json");

  if (!exists(templatePath)) return;

  if (!exists(settingsPath)) {
    const template = await fsp.readFile(templatePath, "utf8");
    const rendered = template.replace(/__DOTFILES_PI__/g, piPkgRoot);
    if (dryRun) {
      log(`dry-run: create Pi settings from template -> ${settingsPath}`);
    } else {
      await fsp.mkdir(path.dirname(settingsPath), { recursive: true });
      await fsp.writeFile(settingsPath, rendered, "utf8");
    }
    log(`created Pi settings.json from template`);
    return;
  }

  const settings = await readJson(settingsPath, {});
  let changed = false;
  for (const entry of settings.packages || []) {
    if (typeof entry !== "object" || !entry?.source) continue;
    const cur = entry.source;
    if (/^(git:|npm:|https?:|ssh:)/.test(cur)) continue;
    if (cur.includes("dotfiles") || cur.includes("agentSync") || cur.includes(".pi")) {
      if (cur !== piPkgRoot) {
        entry.source = piPkgRoot;
        changed = true;
      }
    }
  }
  if (changed) {
    await writeJson(settingsPath, settings, { dryRun, log });
    log(`updated Pi settings package source -> ${piPkgRoot}`);
  }
}

export async function syncPi(cfg, previous, opts = {}) {
  const { dryRun = false, log = () => {}, warn = () => {} } = opts;
  const piPkgRoot = piPackageRoot();
  const managedLinks = {};

  await fsp.mkdir(cfg.pi.agentDir, { recursive: true });

  if (cfg.resources.syncPiAgentContext) {
    const link = path.join(cfg.pi.agentDir, "AGENTS.md");
    const result = await replaceWithSymlink(link, cfg.resources.contextSource, { force: true, dryRun, log });
    if (result.changed) log(`linked Pi AGENTS.md -> ${cfg.resources.contextSource}`);
    managedLinks[link] = cfg.resources.contextSource;

    const prevLink = previous.links?.[link];
    if (prevLink && prevLink !== cfg.resources.contextSource) {
      const removed = await removeManagedLink(link, prevLink, { dryRun, log });
      if (removed) log(`removed stale Pi AGENTS.md link`);
    }
  }

  const modelsJson = path.join(piPkgRoot, "models.json");
  if (exists(modelsJson)) {
    const link = path.join(cfg.pi.agentDir, "models.json");
    const result = await replaceWithSymlink(link, modelsJson, { force: true, dryRun, log });
    if (result.changed) log(`linked Pi models.json -> ${modelsJson}`);
    managedLinks[link] = modelsJson;
  }

  await ensurePiSettings(cfg, { dryRun, log });

  const nodeModules = path.join(piPkgRoot, "node_modules");
  if (exists(path.join(piPkgRoot, "package.json")) && !exists(nodeModules)) {
    warn(`Pi package missing node_modules — run: cd ${piPkgRoot} && npm install`);
  }

  return { managedLinks };
}
