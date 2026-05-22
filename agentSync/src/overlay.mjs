import path from "node:path";
import { exists, readJson, writeJson, backupFileIfExists } from "./fs-utils.mjs";
import { deepMergePreserve, mergeHooks } from "./claude-settings.mjs";

const DEFAULT_OVERLAY_KEYS = [
  "hooks",
  "statusLine",
  "enabledPlugins",
  "extraKnownMarketplaces",
  "skipDangerousModePermissionPrompt",
  "permissions",
];

export function overlayPath(cfg) {
  return cfg.claude.overlayPath || path.join(cfg.stateDir, "claude-overlay.json");
}

function repoOverlayPath(cfg) {
  return path.join(cfg.claude.configsDir, "overlay.json");
}

function mergeOverlays(repo, local) {
  if (!local || typeof local !== "object" || Object.keys(local).length === 0) return repo;
  if (!repo || typeof repo !== "object" || Object.keys(repo).length === 0) return local;

  const out = { ...repo };

  for (const [key, value] of Object.entries(local)) {
    if (key === "hooks") {
      out.hooks = mergeHooks(out.hooks || {}, value);
    } else if (key === "enabledPlugins") {
      out.enabledPlugins = { ...(out.enabledPlugins || {}), ...value };
    } else if (key === "extraKnownMarketplaces") {
      out.extraKnownMarketplaces = deepMergePreserve(out.extraKnownMarketplaces || {}, value);
    } else if (key === "permissions") {
      out.permissions = { ...(out.permissions || {}) };
      if (value.deny) {
        const merged = [...(out.permissions.deny || [])];
        for (const item of value.deny) {
          if (!merged.includes(item)) merged.push(item);
        }
        out.permissions.deny = merged;
      }
      if (value.allow) {
        const merged = [...(out.permissions.allow || [])];
        for (const item of value.allow) {
          if (!merged.includes(item)) merged.push(item);
        }
        out.permissions.allow = merged;
      }
      if (value.defaultMode !== undefined) out.permissions.defaultMode = value.defaultMode;
    } else {
      out[key] = value;
    }
  }

  return out;
}

export async function loadClaudeOverlay(cfg) {
  const repo = await readJson(repoOverlayPath(cfg), {});
  const local = await readJson(overlayPath(cfg), {});
  return mergeOverlays(repo, local);
}

export function applyClaudeOverlay(settings, overlay = {}) {
  if (!overlay || typeof overlay !== "object") return settings;
  if (overlay.hooks) settings.hooks = mergeHooks(settings.hooks || {}, overlay.hooks);
  if (overlay.statusLine !== undefined) settings.statusLine = overlay.statusLine;
  if (overlay.enabledPlugins) settings.enabledPlugins = { ...(settings.enabledPlugins || {}), ...overlay.enabledPlugins };
  if (overlay.extraKnownMarketplaces) settings.extraKnownMarketplaces = deepMergePreserve(settings.extraKnownMarketplaces || {}, overlay.extraKnownMarketplaces);
  if (overlay.permissions) settings.permissions = deepMergePreserve(settings.permissions || {}, overlay.permissions);
  for (const key of ["skipDangerousModePermissionPrompt", "skipWebFetchPreflight", "permissionMode"]) {
    if (overlay[key] !== undefined) settings[key] = overlay[key];
  }
  return settings;
}

export function extractClaudeOverlay(settings, keys = DEFAULT_OVERLAY_KEYS) {
  const overlay = {};
  for (const key of keys) {
    if (settings[key] !== undefined) overlay[key] = settings[key];
  }
  return overlay;
}

function diffOverlay(full, repoBaseline) {
  const local = {};
  for (const [key, value] of Object.entries(full)) {
    if (key === "enabledPlugins") {
      const repoPlugins = repoBaseline.enabledPlugins || {};
      const diff = {};
      for (const [k, v] of Object.entries(value)) {
        if (repoPlugins[k] !== v) diff[k] = v;
      }
      if (Object.keys(diff).length > 0) local.enabledPlugins = diff;
    } else if (key === "permissions") {
      const repoPerm = repoBaseline.permissions || {};
      const localPerm = {};
      if (value.deny) {
        const repoDeny = new Set(repoPerm.deny || []);
        const extra = value.deny.filter((d) => !repoDeny.has(d));
        if (extra.length > 0) localPerm.deny = extra;
      }
      if (value.allow) {
        const repoAllow = new Set(repoPerm.allow || []);
        const extra = value.allow.filter((a) => !repoAllow.has(a));
        if (extra.length > 0) localPerm.allow = extra;
      }
      if (value.defaultMode !== undefined) localPerm.defaultMode = value.defaultMode;
      if (Object.keys(localPerm).length > 0) local.permissions = localPerm;
    } else {
      const repoValue = repoBaseline[key];
      if (JSON.stringify(value) !== JSON.stringify(repoValue)) local[key] = value;
    }
  }
  return local;
}

export async function captureClaudeOverlay(cfg, { dryRun = false, log = () => {} } = {}) {
  const settings = await readJson(cfg.claude.settingsPath, {});
  const full = extractClaudeOverlay(settings);
  const repoBaseline = await readJson(repoOverlayPath(cfg), {});
  const local = diffOverlay(full, repoBaseline);

  const file = overlayPath(cfg);
  if (exists(file)) await backupFileIfExists(file, { dryRun, log });
  await writeJson(file, local, { dryRun, log });
  log(`captured Claude overlay -> ${file} (${Object.keys(local).length} local-only keys)`);
  return local;
}
