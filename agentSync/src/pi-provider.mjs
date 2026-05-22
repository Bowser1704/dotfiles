import { backupFileIfExists, readJson, writeJson } from "./fs-utils.mjs";

export function parsePiModelSpec(spec) {
  const [main, thinking] = spec.split(":", 2);
  const slash = main.indexOf("/");
  if (slash === -1) return { defaultModel: main, defaultThinkingLevel: thinking };
  return {
    defaultProvider: main.slice(0, slash),
    defaultModel: main.slice(slash + 1),
    defaultThinkingLevel: thinking,
  };
}

export async function switchPiProvider(cfg, spec, opts = {}) {
  const { dryRun = false, log = () => {} } = opts;
  if (!spec) throw new Error("Missing Pi model spec, e.g. openai-codex/gpt-5.5:xhigh");
  const patch = parsePiModelSpec(spec);
  const settings = await readJson(cfg.pi.settingsPath, {});
  const before = JSON.stringify(settings, null, 2);
  for (const [key, value] of Object.entries(patch)) {
    if (value) settings[key] = value;
  }
  const after = JSON.stringify(settings, null, 2);
  if (before === after) {
    log(`Pi already uses ${spec}`);
    return settings;
  }
  const backup = await backupFileIfExists(cfg.pi.settingsPath, { dryRun, log });
  await writeJson(cfg.pi.settingsPath, settings, { dryRun, log });
  if (backup) log(`backed up Pi settings -> ${backup}`);
  log(`Pi default model switched to ${settings.defaultProvider || "<unchanged>"}/${settings.defaultModel}${settings.defaultThinkingLevel ? `:${settings.defaultThinkingLevel}` : ""}`);
  return settings;
}
