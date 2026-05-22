import path from "node:path";
import { fileURLToPath } from "node:url";
import { HOME, exists, readJson, resolvePath, writeJson } from "./fs-utils.mjs";

const __filename = fileURLToPath(import.meta.url);
export const PROJECT_ROOT = path.resolve(path.dirname(__filename), "..");

export const DEFAULT_REQUIRED_CLAUDE_HOOK = "/Users/hongqi/.r2c/scripts/claude-cli-hook.sh";

export function defaultConfig() {
  return {
    stateDir: "~/.agent-sync",
    pi: {
      agentDir: process.env.PI_CODING_AGENT_DIR || "~/.pi/agent",
      settingsPath: "~/.pi/agent/settings.json",
    },
    claude: {
      dir: process.env.CLAUDE_CONFIG_DIR || "~/.claude",
      settingsPath: "~/.claude/settings.json",
      configsDir: path.join(PROJECT_ROOT, "claude"),
      overlayPath: undefined,
      requiredHooks: [
        { event: "PreToolUse", matcher: "Bash", command: `bash ${DEFAULT_REQUIRED_CLAUDE_HOOK}`, timeout: 15 },
        { event: "PostToolUse", matcher: "Bash", command: `bash ${DEFAULT_REQUIRED_CLAUDE_HOOK}`, timeout: 15 },
        { event: "PostToolUseFailure", matcher: "Bash", command: `bash ${DEFAULT_REQUIRED_CLAUDE_HOOK}`, timeout: 15 },
      ],
    },
    resources: {
      skillDirs: [
        path.join(PROJECT_ROOT, "..", "pi", "skills"),
        path.join(PROJECT_ROOT, "..", "pi", "skills-private"),
      ],
      promptDirs: [
        path.join(PROJECT_ROOT, "..", "pi", "prompts"),
      ],
      extraSkillDirs: [],
    },
    providers: {
      path: path.join(PROJECT_ROOT, "providers.json"),
    },
    providerSwitch: {
      // Env keys matching these prefixes are Claude-provider owned and are replaced on switch.
      envKeyPrefixes: [
        "ANTHROPIC_",
        "OPENAI_",
        "AZURE_OPENAI_",
        "GOOGLE_",
        "GEMINI_",
        "DASHSCOPE_",
        "DEEPSEEK_",
        "XAI_",
        "GROQ_",
        "MISTRAL_",
        "CLAUDE_CODE_EXPERIMENTAL_",
      ],
      // Default switch is conservative: replace provider env only and preserve Claude settings.
      // Set true if you want to also merge hooks/plugins/statusLine stored in cc-switch provider profiles.
      mergeProviderSettings: false,
      setTopLevelKeysOnlyIfMissing: ["statusLine"],
    },
  };
}

function mergeConfig(base, overlay) {
  if (Array.isArray(base) || Array.isArray(overlay)) return overlay ?? base;
  if (!overlay || typeof overlay !== "object") return overlay ?? base;
  const out = { ...(base || {}) };
  for (const [key, value] of Object.entries(overlay)) {
    if (value && typeof value === "object" && !Array.isArray(value) && base?.[key] && typeof base[key] === "object" && !Array.isArray(base[key])) {
      out[key] = mergeConfig(base[key], value);
    } else {
      out[key] = value;
    }
  }
  return out;
}

export async function loadConfig(configPath) {
  const defaults = defaultConfig();
  const candidates = [
    configPath,
    process.env.AGENT_SYNC_CONFIG,
    path.join(HOME, ".agent-sync", "config.json"),
    path.join(PROJECT_ROOT, "agent-sync.config.json"),
  ].filter(Boolean);

  let cfg = defaults;
  let loadedFrom;
  for (const candidate of candidates) {
    const file = resolvePath(candidate);
    if (!exists(file)) continue;
    const overlay = await readJson(file, {});
    cfg = mergeConfig(cfg, overlay);
    loadedFrom = file;
    break;
  }

  const stateDir = resolvePath(cfg.stateDir);
  const piAgentDir = resolvePath(cfg.pi.agentDir);
  const claudeDir = resolvePath(cfg.claude.dir);

  cfg.__loadedFrom = loadedFrom;
  cfg.stateDir = stateDir;
  cfg.manifestPath = path.join(stateDir, "manifest.json");
  cfg.statePath = path.join(stateDir, "state.json");
  cfg.pi.agentDir = piAgentDir;
  cfg.pi.settingsPath = resolvePath(cfg.pi.settingsPath || path.join(piAgentDir, "settings.json"));
  cfg.claude.dir = claudeDir;
  cfg.claude.settingsPath = resolvePath(cfg.claude.settingsPath || path.join(claudeDir, "settings.json"));
  if (cfg.claude.overlayPath) cfg.claude.overlayPath = resolvePath(cfg.claude.overlayPath);
  cfg.resources.skillDirs = (cfg.resources.skillDirs || []).map((p) => resolvePath(p));
  cfg.resources.promptDirs = (cfg.resources.promptDirs || []).map((p) => resolvePath(p));
  cfg.resources.extraSkillDirs = (cfg.resources.extraSkillDirs || []).map((p) => resolvePath(p));
  cfg.providers.path = resolvePath(cfg.providers.path);
  return cfg;
}

export async function ensureUserConfig(cfg, { dryRun = false, log = () => {} } = {}) {
  const file = path.join(cfg.stateDir, "config.json");
  if (exists(file)) return file;
  const userConfig = {
    resources: {
      extraSkillDirs: cfg.resources.extraSkillDirs.map((p) => p.replace(HOME, "~")),
    },
    claude: {
      requiredHooks: cfg.claude.requiredHooks,
    },
  };
  await writeJson(file, userConfig, { dryRun, log });
  return file;
}
