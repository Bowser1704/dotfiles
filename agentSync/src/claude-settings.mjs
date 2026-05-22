import { backupFileIfExists, readJson, writeJson } from "./fs-utils.mjs";

export function deepMergePreserve(base, overlay) {
  if (!overlay || typeof overlay !== "object" || Array.isArray(overlay)) return base;
  const out = { ...(base || {}) };
  for (const [key, value] of Object.entries(overlay)) {
    if (value && typeof value === "object" && !Array.isArray(value) && out[key] && typeof out[key] === "object" && !Array.isArray(out[key])) {
      out[key] = deepMergePreserve(out[key], value);
    } else if (out[key] === undefined) {
      out[key] = value;
    } else if (key === "enabledPlugins" || key === "extraKnownMarketplaces" || key === "permissions") {
      out[key] = deepMergePreserve(out[key], value);
    }
  }
  return out;
}

function hookKey(eventName, entry, hook) {
  return JSON.stringify({
    eventName,
    matcher: entry.matcher || "",
    type: hook.type || "",
    command: hook.command || "",
    timeout: hook.timeout || undefined,
  });
}

export function mergeHooks(targetHooks = {}, sourceHooks = {}) {
  const out = { ...targetHooks };
  const seen = new Set();
  for (const [eventName, entries] of Object.entries(out)) {
    if (!Array.isArray(entries)) continue;
    for (const entry of entries) {
      for (const hook of entry.hooks || []) seen.add(hookKey(eventName, entry, hook));
    }
  }

  for (const [eventName, entries] of Object.entries(sourceHooks || {})) {
    if (!Array.isArray(entries)) continue;
    out[eventName] = Array.isArray(out[eventName]) ? out[eventName] : [];
    for (const entry of entries) {
      const hooks = Array.isArray(entry.hooks) ? entry.hooks : [];
      const newHooks = [];
      for (const hook of hooks) {
        const key = hookKey(eventName, entry, hook);
        if (seen.has(key)) continue;
        seen.add(key);
        newHooks.push(hook);
      }
      if (newHooks.length > 0) out[eventName].push({ ...entry, hooks: newHooks });
    }
  }
  return out;
}

export function ensureRequiredHooks(settings, requiredHooks) {
  settings.hooks ||= {};
  for (const required of requiredHooks || []) {
    const eventName = required.event;
    const entry = {
      matcher: required.matcher || "Bash",
      hooks: [{ type: "command", command: required.command, timeout: required.timeout ?? 15 }],
    };
    settings.hooks = mergeHooks(settings.hooks, { [eventName]: [entry] });
  }
}

export function mergeClaudeSettingsForSync(settings, cfg, resources) {
  ensureRequiredHooks(settings, cfg.claude.requiredHooks);

  settings.permissions ||= {};
  settings.permissions.allow = Array.isArray(settings.permissions.allow) ? settings.permissions.allow : [];
  settings.permissions.deny = Array.isArray(settings.permissions.deny) ? settings.permissions.deny : [];

  const allow = settings.permissions.allow;
  const pushUnique = (array, value) => {
    if (!array.includes(value)) array.push(value);
  };

  for (const root of cfg.resources.extraSkillDirs || []) pushUnique(allow, `Read(${root}/**)`);
  for (const skillName of [...resources.skills.keys()].sort()) pushUnique(allow, `Skill(${skillName})`);

  settings.agentSync ||= {};
  settings.agentSync.managedBy = "agentSync";
  settings.agentSync.syncedSkills = [...resources.skills.keys()].sort();
  settings.agentSync.syncedCommands = [...resources.prompts.keys()].sort();
}

export function envKeyIsProviderOwned(key, cfg, previousState = {}) {
  if (previousState?.claudeProvider?.envKeys?.includes(key)) return true;
  return (cfg.providerSwitch.envKeyPrefixes || []).some((prefix) => key.startsWith(prefix));
}

function applyProviderObject(settings, providerObject, cfg, { previousState = {}, asCommon = false } = {}) {
  if (!providerObject || typeof providerObject !== "object") return;

  if (providerObject.env && typeof providerObject.env === "object") {
    settings.env ||= {};
    if (!asCommon) {
      for (const key of Object.keys(settings.env)) {
        if (envKeyIsProviderOwned(key, cfg, previousState)) delete settings.env[key];
      }
    }
    for (const [key, value] of Object.entries(providerObject.env)) settings.env[key] = value;
  }

  if (!cfg.providerSwitch.mergeProviderSettings) return;

  if (providerObject.hooks) settings.hooks = mergeHooks(settings.hooks || {}, providerObject.hooks);
  if (providerObject.enabledPlugins) settings.enabledPlugins = { ...(settings.enabledPlugins || {}), ...providerObject.enabledPlugins };
  if (providerObject.extraKnownMarketplaces) {
    settings.extraKnownMarketplaces = deepMergePreserve(settings.extraKnownMarketplaces || {}, providerObject.extraKnownMarketplaces);
  }
  if (providerObject.permissions) settings.permissions = deepMergePreserve(settings.permissions || {}, providerObject.permissions);

  for (const key of cfg.providerSwitch.setTopLevelKeysOnlyIfMissing || []) {
    if (providerObject[key] !== undefined && settings[key] === undefined) settings[key] = providerObject[key];
  }
}

export function switchClaudeProviderSettings(settings, providerConfig, commonConfig, cfg, previousState = {}) {
  if (commonConfig) applyProviderObject(settings, commonConfig, cfg, { previousState, asCommon: true });
  applyProviderObject(settings, providerConfig, cfg, { previousState, asCommon: false });
  ensureRequiredHooks(settings, cfg.claude.requiredHooks);
  return settings;
}

export async function writeClaudeSettingsIfChanged(settingsPath, before, after, { dryRun = false, log = () => {} } = {}) {
  if (JSON.stringify(before, null, 2) === JSON.stringify(after, null, 2)) return false;
  const backup = await backupFileIfExists(settingsPath, { dryRun, log });
  await writeJson(settingsPath, after, { dryRun, log });
  if (backup) log(`backed up Claude settings -> ${backup}`);
  log(`updated Claude settings: ${settingsPath}`);
  return true;
}

export async function loadClaudeSettings(cfg) {
  return readJson(cfg.claude.settingsPath, {});
}
