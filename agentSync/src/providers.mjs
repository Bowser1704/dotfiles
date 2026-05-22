import { exists, readJson, writeJson } from "./fs-utils.mjs";
import { loadClaudeSettings, switchClaudeProviderSettings, writeClaudeSettingsIfChanged } from "./claude-settings.mjs";
import { applyClaudeOverlay, loadClaudeOverlay } from "./overlay.mjs";

export async function loadProviders(cfg) {
  if (!exists(cfg.providers.path)) return [];
  return readJson(cfg.providers.path, []);
}

export function resolveEnvRefs(env) {
  const resolved = {};
  for (const [key, value] of Object.entries(env)) {
    if (typeof value === "string" && value.startsWith("$")) {
      const varName = value.slice(1);
      resolved[key] = process.env[varName] || "";
    } else {
      resolved[key] = value;
    }
  }
  return resolved;
}

function summarizeProvider(provider) {
  return {
    id: provider.id,
    name: provider.name,
    category: provider.category || "custom",
    current: Boolean(provider.current),
    baseUrl: provider.env?.ANTHROPIC_BASE_URL || provider.env?.OPENAI_BASE_URL || "",
    model: provider.env?.ANTHROPIC_MODEL || provider.env?.OPENAI_MODEL || "",
    envKeys: Object.keys(provider.env || {}),
  };
}

export async function resolveProvider(cfg, query) {
  const providers = await loadProviders(cfg);
  if (!query) return providers.find((p) => p.current) || providers[0];
  const q = query.toLowerCase();
  const exact = providers.filter((p) => p.id === query || p.name.toLowerCase() === q);
  if (exact.length === 1) return exact[0];
  if (exact.length > 1) throw new Error(`Provider query '${query}' matched multiple: ${exact.map((p) => p.name).join(", ")}`);
  const fuzzy = providers.filter((p) => p.id.toLowerCase().includes(q) || p.name.toLowerCase().includes(q));
  if (fuzzy.length === 1) return fuzzy[0];
  if (fuzzy.length > 1) throw new Error(`Provider query '${query}' matched multiple: ${fuzzy.map((p) => `${p.name} (${p.id})`).join(", ")}`);
  throw new Error(`No provider matched '${query}'`);
}

export async function printProviders(cfg, { json = false } = {}) {
  const providers = (await loadProviders(cfg)).map(summarizeProvider);
  if (json) {
    console.log(JSON.stringify(providers, null, 2));
    return providers;
  }
  const rows = providers.map((p) => ({
    current: p.current ? "*" : " ",
    id: p.id,
    name: p.name,
    baseUrl: p.baseUrl,
    model: p.model,
  }));
  const widths = {
    id: Math.max(2, ...rows.map((r) => r.id.length)),
    name: Math.max(4, ...rows.map((r) => r.name.length)),
    model: Math.max(5, ...rows.map((r) => r.model.length)),
  };
  console.log(`  ${"ID".padEnd(widths.id)}  ${"NAME".padEnd(widths.name)}  ${"MODEL".padEnd(widths.model)}  BASE_URL`);
  for (const r of rows) {
    console.log(`${r.current} ${r.id.padEnd(widths.id)}  ${r.name.padEnd(widths.name)}  ${r.model.padEnd(widths.model)}  ${r.baseUrl}`);
  }
  return providers;
}

export async function switchProvider(cfg, query, opts = {}) {
  const { dryRun = false, log = () => {} } = opts;
  const provider = await resolveProvider(cfg, query);
  const previousState = await readJson(cfg.statePath, {});

  const resolvedEnv = resolveEnvRefs(provider.env || {});
  const providerConfig = { env: resolvedEnv };

  const before = await loadClaudeSettings(cfg);
  const after = JSON.parse(JSON.stringify(before));
  applyClaudeOverlay(after, await loadClaudeOverlay(cfg));
  switchClaudeProviderSettings(after, providerConfig, undefined, cfg, previousState);

  await writeClaudeSettingsIfChanged(cfg.claude.settingsPath, before, after, { dryRun, log });

  const envKeys = Object.keys(provider.env || {});
  const state = {
    ...previousState,
    claudeProvider: {
      source: "providers.json",
      id: provider.id,
      name: provider.name,
      category: provider.category || "custom",
      envKeys,
      switchedAt: new Date().toISOString(),
    },
  };
  await writeJson(cfg.statePath, state, { dryRun, log });

  log(`Claude provider switched to ${provider.name} (${provider.id})`);
  return { provider: summarizeProvider(provider) };
}

export async function inspectLiveClaudeProvider(cfg) {
  const settings = await loadClaudeSettings(cfg);
  const env = settings.env || {};
  return {
    baseUrl: env.ANTHROPIC_BASE_URL,
    model: env.ANTHROPIC_MODEL,
    reasoningModel: env.ANTHROPIC_REASONING_MODEL,
    envKeys: Object.keys(env).sort(),
    hasStatusLine: settings.statusLine !== undefined,
    hookEvents: Object.keys(settings.hooks || {}).sort(),
    enabledPlugins: Object.keys(settings.enabledPlugins || {}).sort(),
  };
}
