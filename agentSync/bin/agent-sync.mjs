#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { loadConfig, ensureUserConfig } from "../src/config.mjs";
import { readJson } from "../src/fs-utils.mjs";
import { loadManifest, writeManifest } from "../src/resources.mjs";
import { syncClaude } from "../src/sync-claude.mjs";
import { syncPi } from "../src/sync-pi.mjs";
import { printProviders, switchProvider, inspectLiveClaudeProvider } from "../src/providers.mjs";
import { switchPiProvider } from "../src/pi-provider.mjs";
import { captureClaudeOverlay } from "../src/overlay.mjs";
import { buildInventory, printInventory } from "../src/inventory.mjs";

function parseArgs(argv) {
  const args = [];
  const flags = {};
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--") {
      args.push(...argv.slice(i + 1));
      break;
    }
    if (!arg.startsWith("-")) {
      args.push(arg);
      continue;
    }
    const [key, inlineValue] = arg.replace(/^--?/, "").split("=", 2);
    if (inlineValue !== undefined) flags[key] = inlineValue;
    else if (i + 1 < argv.length && !argv[i + 1].startsWith("-")) flags[key] = argv[++i];
    else flags[key] = true;
  }
  return { args, flags };
}

function usage() {
  console.log(`agent-sync — portable coding agent config manager

Usage:
  agent-sync init [--dry-run]
  agent-sync sync [claude|pi] [--dry-run] [--quiet]
  agent-sync watch
  agent-sync status [--json]
  agent-sync inventory [--json] [--project-root <path>]
  agent-sync overlay capture [--dry-run]
  agent-sync providers list [--app claude] [--json]
  agent-sync providers switch <provider-id-or-name> [--dry-run]
  agent-sync providers current [--json]
  agent-sync pi switch <provider/model[:thinking]> [--dry-run]

Examples:
  agent-sync sync                # sync all agents
  agent-sync sync claude         # sync Claude Code only
  agent-sync sync pi             # sync Pi only
  agent-sync providers list
  agent-sync providers switch idealab
  agent-sync pi switch openai-codex/gpt-5.5:xhigh
`);
}

const KNOWN_AGENTS = ["claude", "pi"];

const { args, flags } = parseArgs(process.argv.slice(2));
const cmd = args[0] || "sync";
const dryRun = Boolean(flags["dry-run"] || flags.n);
const quiet = Boolean(flags.quiet || flags.q);
const log = quiet ? () => {} : (message) => console.log(message);
const warn = (message) => console.warn(`warning: ${message}`);
const cfg = await loadConfig(flags.config);

async function commandSync(agent) {
  if (agent && !KNOWN_AGENTS.includes(agent)) {
    throw new Error(`Unknown agent: ${agent}. Known agents: ${KNOWN_AGENTS.join(", ")}`);
  }

  const previous = await loadManifest(cfg);
  const allLinks = {};
  let skills = [];
  let commands = [];
  let deployedConfigs = [];

  if (!agent || agent === "claude") {
    const result = await syncClaude(cfg, previous, { dryRun, log, warn });
    Object.assign(allLinks, result.managedLinks);
    skills = result.skills;
    commands = result.commands;
    deployedConfigs = result.deployedConfigs;
    log(`synced Claude: ${skills.length} skills, ${commands.length} commands${deployedConfigs.length ? `, ${deployedConfigs.length} configs` : ""}`);
  }

  if (!agent || agent === "pi") {
    const result = await syncPi(cfg, previous, { dryRun, log, warn });
    Object.assign(allLinks, result.managedLinks);
    log(`synced Pi`);
  }

  const manifest = {
    version: 1,
    managedBy: "agentSync",
    source: cfg.resources.contextSource,
    piSettings: cfg.pi.settingsPath,
    claudeSettings: cfg.claude.settingsPath,
    updatedAt: new Date().toISOString(),
    links: allLinks,
    skills,
    commands,
    deployedConfigs,
  };
  await writeManifest(cfg, manifest, { dryRun, log });
  return manifest;
}

async function commandStatus() {
  const manifest = await readJson(cfg.manifestPath, {});
  const liveClaude = await inspectLiveClaudeProvider(cfg).catch((error) => ({ error: error.message }));
  const state = await readJson(cfg.statePath, {});
  const status = { config: cfg.__loadedFrom || "defaults", manifest, state, liveClaude };
  if (flags.json) console.log(JSON.stringify(status, null, 2));
  else {
    console.log(`config: ${status.config}`);
    console.log(`source: ${manifest.source || cfg.resources.contextSource}`);
    console.log(`skills: ${(manifest.skills || []).join(", ") || "<none>"}`);
    console.log(`commands: ${(manifest.commands || []).join(", ") || "<none>"}`);
    if ((manifest.deployedConfigs || []).length) console.log(`configs: ${manifest.deployedConfigs.join(", ")}`);
    if (state.claudeProvider) console.log(`claude provider state: ${state.claudeProvider.name} (${state.claudeProvider.id})`);
    if (liveClaude.error) console.log(`live claude: ${liveClaude.error}`);
    else console.log(`live claude: ${liveClaude.model || "<official/default>"} ${liveClaude.baseUrl || ""}`.trim());
  }
}

async function commandWatch() {
  await commandSync();
  const watchPaths = [
    cfg.resources.contextSource,
    cfg.pi.settingsPath,
    cfg.claude.settingsPath,
    cfg.claude.configsDir,
    cfg.providers.path,
    path.dirname(cfg.resources.contextSource),
    ...(cfg.resources.skillDirs || []),
    ...(cfg.resources.promptDirs || []),
    ...(cfg.resources.extraSkillDirs || []),
  ].filter((p, idx, arr) => p && fs.existsSync(p) && arr.indexOf(p) === idx);

  log("watching:");
  for (const p of watchPaths) log(`  - ${p}`);

  let timer;
  const rerun = (changed) => {
    clearTimeout(timer);
    timer = setTimeout(async () => {
      try {
        log(`change detected: ${changed}`);
        await commandSync();
        log("sync complete; run /reload in pi or restart/reload Claude Code if needed");
      } catch (error) {
        console.error(error.stack || error.message);
      }
    }, 250);
  };

  for (const p of watchPaths) {
    const stat = fs.statSync(p);
    fs.watch(p, { recursive: stat.isDirectory() }, (_event, filename) => rerun(filename ? path.join(p, filename.toString()) : p));
  }
  await new Promise(() => {});
}

try {
  if (cmd === "help" || flags.help || flags.h) {
    usage();
  } else if (cmd === "init") {
    const file = await ensureUserConfig(cfg, { dryRun, log });
    log(`config: ${file}`);
  } else if (["sync", "apply", "build"].includes(cmd)) {
    const agent = args[1];
    await commandSync(agent);
  } else if (cmd === "watch") {
    await commandWatch();
  } else if (cmd === "status") {
    await commandStatus();
  } else if (cmd === "inventory") {
    const roots = [];
    if (flags["project-root"]) roots.push(flags["project-root"]);
    else roots.push(process.cwd(), "/Users/hongqi/codebase/scripts");
    const inv = await buildInventory(cfg, { projectRoots: roots });
    if (flags.json) console.log(JSON.stringify(inv, null, 2));
    else printInventory(inv);
  } else if (cmd === "overlay") {
    const sub = args[1] || "capture";
    if (sub !== "capture") throw new Error(`Unknown overlay subcommand: ${sub}`);
    await captureClaudeOverlay(cfg, { dryRun, log });
  } else if (cmd === "providers" || cmd === "provider") {
    const sub = args[1] || "list";
    if (sub === "list" || sub === "ls") {
      await printProviders(cfg, { json: Boolean(flags.json) });
    } else if (sub === "switch" || sub === "use") {
      const query = args.slice(2).join(" ").trim();
      if (!query) throw new Error("Missing provider id/name");
      const result = await switchProvider(cfg, query, { dryRun, log });
      if (flags.json) console.log(JSON.stringify(result, null, 2));
    } else if (sub === "current") {
      const current = await inspectLiveClaudeProvider(cfg);
      console.log(flags.json ? JSON.stringify(current, null, 2) : `${current.model || "<official/default>"} ${current.baseUrl || ""}`.trim());
    } else {
      throw new Error(`Unknown providers subcommand: ${sub}`);
    }
  } else if (cmd === "pi") {
    const sub = args[1] || "switch";
    if (sub !== "switch" && sub !== "use") throw new Error(`Unknown pi subcommand: ${sub}`);
    await switchPiProvider(cfg, args[2], { dryRun, log });
  } else {
    usage();
    process.exitCode = 2;
  }
} catch (error) {
  console.error(error.stack || error.message);
  process.exit(1);
}
