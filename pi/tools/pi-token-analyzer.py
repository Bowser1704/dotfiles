#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
pi-token-analyzer: Analyze token usage in pi sessions.
Usage:
  pi-token-analyzer.py                  # Print summary table
  pi-token-analyzer.py --context        # Analyze current context components
  pi-token-analyzer.py --open           # Generate HTML and open in browser
  pi-token-analyzer.py --html           # Output HTML to stdout
"""

import json
import os
import sys
import argparse
from pathlib import Path

def count_tokens(text: str) -> int:
    # ~4 chars per token (standard approximation for Claude/GPT)
    return max(1, len(text) // 4)

SESSIONS_DIR = Path.home() / ".pi/agent/sessions"
SKILLS_DIRS = [
    Path.home() / ".dotfiles/pi/skills",
    Path.home() / ".agents/skills",
    Path.home() / ".pi/agent/git",
    Path("/opt/homebrew/lib/node_modules/pi-lens/skills"),
    Path("/opt/homebrew/lib/node_modules/pi-total-recall/node_modules/pi-session-search/skills"),
]


def load_session(path: Path) -> dict:
    """Load a single session JSONL file."""
    messages = []
    session_info = {}
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                obj = json.loads(line)
                if obj.get("type") == "session":
                    session_info = obj
                elif obj.get("type") == "message":
                    messages.append(obj)
    except Exception as e:
        return {"error": str(e), "path": str(path)}

    turns = []
    for m in messages:
        msg = m.get("message", {})
        role = msg.get("role", "?")
        usage = msg.get("usage", {})
        content = msg.get("content", [])

        content_types = []
        content_preview = ""
        if isinstance(content, list):
            for c in content:
                t = c.get("type", "?")
                content_types.append(t)
                if t == "text" and not content_preview:
                    content_preview = c.get("text", "")[:120]
                elif t == "toolCall" and not content_preview:
                    content_preview = f"[{c.get('name', '?')}]"
        elif isinstance(content, str):
            content_types = ["text"]
            content_preview = content[:120]

        turn = {
            "id": m.get("id"),
            "ts": m.get("timestamp"),
            "role": role,
            "types": content_types,
            "preview": content_preview,
        }
        if usage:
            turn["input"] = usage.get("input", 0)
            turn["output"] = usage.get("output", 0)
            turn["cacheRead"] = usage.get("cacheRead", 0)
            turn["cacheWrite"] = usage.get("cacheWrite", 0)
            turn["total"] = usage.get("totalTokens", 0)
            turn["model"] = msg.get("model", "?")
        turns.append(turn)

    # First assistant turn's cacheWrite ≈ system prompt size
    system_prompt_size = 0
    for t in turns:
        if t["role"] == "assistant" and "cacheWrite" in t:
            system_prompt_size = t["cacheWrite"]
            break

    name = path.parent.name.replace("--", "/").strip("/")
    ts = session_info.get("timestamp", path.stem.split("_")[0])

    return {
        "id": session_info.get("id", path.stem),
        "path": str(path),
        "project": name,
        "cwd": session_info.get("cwd", "?"),
        "timestamp": ts,
        "turns": turns,
        "system_prompt_tokens": system_prompt_size,
        "total_input": sum(t.get("input", 0) for t in turns),
        "total_output": sum(t.get("output", 0) for t in turns),
        "total_cache_read": sum(t.get("cacheRead", 0) for t in turns),
        "total_cache_write": sum(t.get("cacheWrite", 0) for t in turns),
        "total_tokens": sum(t.get("total", 0) for t in turns),
    }


def load_all_sessions(limit_per_project: int = 10) -> list[dict]:
    """Load all sessions from all projects."""
    sessions = []
    if not SESSIONS_DIR.exists():
        return sessions

    for project_dir in sorted(SESSIONS_DIR.iterdir()):
        if not project_dir.is_dir():
            continue
        files = sorted(project_dir.glob("*.jsonl"), reverse=True)[:limit_per_project]
        for f in files:
            s = load_session(f)
            if "error" not in s:
                sessions.append(s)

    sessions.sort(key=lambda x: x["timestamp"], reverse=True)
    return sessions


def analyze_context() -> dict:
    """Analyze current context components and estimate token usage."""
    components = []

    def add(name: str, content: str, category: str):
        tokens = count_tokens(content)
        components.append({
            "name": name,
            "category": category,
            "chars": len(content),
            "tokens": tokens,
            "preview": content[:200].replace("\n", " "),
        })

    # 1. Project AGENTS.md files (search cwd ancestors)
    cwd = Path.cwd()
    for d in [cwd, *cwd.parents]:
        agents_md = d / "AGENTS.md"
        if agents_md.exists():
            add(f"AGENTS.md ({d.name})", agents_md.read_text(), "project")
            break

    # 2. Skills
    for skills_root in SKILLS_DIRS:
        if not skills_root.exists():
            continue
        for skill_dir in sorted(skills_root.iterdir()):
            skill_md = skill_dir / "SKILL.md" if skill_dir.is_dir() else None
            if skill_md and skill_md.exists():
                content = skill_md.read_text()
                # Check if disabled
                disabled = "disable-model-invocation: true" in content[:500]
                if not disabled:
                    # Only description is in system prompt (not full content)
                    desc = ""
                    for line in content[:1000].splitlines():
                        if "description:" in line.lower():
                            desc = line.strip()
                            break
                    add(
                        f"skill:{skill_dir.name}",
                        desc or content[:300],
                        "skill-active",
                    )
                else:
                    add(f"skill:{skill_dir.name} [DISABLED]", "", "skill-disabled")
        # Also handle .md files directly in skills root (for ~/.pi/agent/skills/)
        for md_file in skills_root.glob("*.md"):
            content = md_file.read_text()
            disabled = "disable-model-invocation: true" in content[:500]
            if not disabled:
                add(f"skill:{md_file.stem}", content[:300], "skill-active")

    # 3. Pi settings / memory
    memory_dir = Path.home() / ".pi/memory"
    if memory_dir.exists():
        all_mem = ""
        for f in memory_dir.glob("*.md"):
            all_mem += f.read_text()
        if all_mem:
            add("~/.pi/memory (facts/lessons)", all_mem, "memory")

    # 4. .pi/settings.json (recent sessions injected?)
    settings_file = Path.home() / ".pi/agent/settings.json"
    if settings_file.exists():
        add("pi settings.json", settings_file.read_text(), "config")

    total = sum(c["tokens"] for c in components if c.get("category") != "skill-disabled")
    return {
        "components": components,
        "total_estimated_tokens": total,
        "note": "Tool definitions not included (they are dynamic; ~4000-6000 tokens estimated)",
    }


def generate_html(sessions: list[dict], context: dict) -> str:
    data_json = json.dumps({"sessions": sessions, "context": context}, ensure_ascii=False)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Pi Token Analyzer</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0f0f10; color: #e1e1e6; }}
  .layout {{ display: grid; grid-template-columns: 320px 1fr; height: 100vh; }}
  .sidebar {{ background: #1a1a1e; border-right: 1px solid #2a2a30; overflow-y: auto; }}
  .sidebar-header {{ padding: 16px; font-size: 13px; font-weight: 600; color: #888; text-transform: uppercase; letter-spacing: .08em; border-bottom: 1px solid #2a2a30; }}
  .session-item {{ padding: 12px 16px; cursor: pointer; border-bottom: 1px solid #1e1e22; transition: background .15s; }}
  .session-item:hover {{ background: #22222a; }}
  .session-item.active {{ background: #1e2a3a; border-left: 3px solid #3b82f6; }}
  .session-project {{ font-size: 11px; color: #666; margin-bottom: 2px; }}
  .session-ts {{ font-size: 12px; color: #aaa; margin-bottom: 4px; }}
  .session-tokens {{ display: flex; gap: 8px; flex-wrap: wrap; }}
  .badge {{ font-size: 10px; padding: 2px 6px; border-radius: 10px; }}
  .badge-total {{ background: #2a3a4a; color: #60a5fa; }}
  .badge-sys {{ background: #2a2a40; color: #a78bfa; }}
  .badge-turns {{ background: #1a2a1a; color: #4ade80; }}
  .main {{ overflow-y: auto; padding: 24px; }}
  .tabs {{ display: flex; gap: 2px; margin-bottom: 24px; }}
  .tab {{ padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 13px; background: #1a1a1e; color: #888; }}
  .tab.active {{ background: #1e2a3a; color: #60a5fa; }}
  .section {{ background: #1a1a1e; border-radius: 10px; padding: 20px; margin-bottom: 20px; }}
  .section h2 {{ font-size: 14px; color: #888; margin-bottom: 16px; font-weight: 600; }}
  .stats-grid {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 20px; }}
  .stat-card {{ background: #12121a; border-radius: 8px; padding: 14px; }}
  .stat-label {{ font-size: 11px; color: #666; margin-bottom: 4px; }}
  .stat-value {{ font-size: 22px; font-weight: 700; }}
  .stat-value.blue {{ color: #60a5fa; }}
  .stat-value.purple {{ color: #a78bfa; }}
  .stat-value.green {{ color: #4ade80; }}
  .stat-value.orange {{ color: #fb923c; }}
  .chart-container {{ position: relative; height: 240px; }}
  table {{ width: 100%; border-collapse: collapse; font-size: 12px; }}
  th {{ text-align: left; padding: 8px 10px; color: #666; font-weight: 600; border-bottom: 1px solid #2a2a30; font-size: 11px; }}
  td {{ padding: 7px 10px; border-bottom: 1px solid #1e1e22; }}
  tr:hover td {{ background: #1e1e24; }}
  .role-user {{ color: #60a5fa; }}
  .role-assistant {{ color: #4ade80; }}
  .role-tool {{ color: #fb923c; }}
  .bar {{ height: 6px; border-radius: 3px; background: #2a2a30; margin-top: 3px; overflow: hidden; }}
  .bar-fill {{ height: 100%; border-radius: 3px; }}
  .ctx-cat-project {{ color: #fb923c; }}
  .ctx-cat-skill-active {{ color: #4ade80; }}
  .ctx-cat-skill-disabled {{ color: #444; text-decoration: line-through; }}
  .ctx-cat-memory {{ color: #a78bfa; }}
  .ctx-cat-config {{ color: #60a5fa; }}
  .empty {{ color: #555; font-size: 13px; text-align: center; padding: 40px; }}
</style>
</head>
<body>
<div class="layout">
  <div class="sidebar">
    <div class="sidebar-header">Sessions</div>
    <div id="session-list"></div>
  </div>
  <div class="main">
    <div class="tabs">
      <div class="tab active" onclick="showTab('session')">Session</div>
      <div class="tab" onclick="showTab('context')">Context Breakdown</div>
    </div>
    <div id="tab-session"></div>
    <div id="tab-context" style="display:none"></div>
  </div>
</div>

<script>
const DATA = {data_json};
const sessions = DATA.sessions;
const ctx = DATA.context;
let currentSession = null;
let turnChart = null;

function fmt(n) {{
  if (n >= 1000000) return (n/1000000).toFixed(1)+'M';
  if (n >= 1000) return (n/1000).toFixed(1)+'k';
  return n+'';
}}
function fmtTs(ts) {{
  try {{ return new Date(ts).toLocaleString(); }} catch {{ return ts; }}
}}
function roleClass(r) {{
  if (r === 'user') return 'role-user';
  if (r === 'assistant') return 'role-assistant';
  return 'role-tool';
}}

// Sidebar
const list = document.getElementById('session-list');
sessions.forEach((s, i) => {{
  const el = document.createElement('div');
  el.className = 'session-item';
  el.dataset.idx = i;
  const assistantTurns = s.turns.filter(t => t.role === 'assistant').length;
  el.innerHTML = `
    <div class="session-project">${{s.project.split('/').slice(-2).join('/')}}</div>
    <div class="session-ts">${{fmtTs(s.timestamp)}}</div>
    <div class="session-tokens">
      <span class="badge badge-total">total ${{fmt(s.total_tokens)}}</span>
      <span class="badge badge-sys">sys ~${{fmt(s.system_prompt_tokens)}}</span>
      <span class="badge badge-turns">${{assistantTurns}} turns</span>
    </div>
  `;
  el.onclick = () => selectSession(i);
  list.appendChild(el);
}});

function selectSession(idx) {{
  document.querySelectorAll('.session-item').forEach(el => el.classList.remove('active'));
  document.querySelector(`[data-idx="${{idx}}"]`).classList.add('active');
  currentSession = sessions[idx];
  renderSession(currentSession);
}}

function renderSession(s) {{
  const assistantTurns = s.turns.filter(t => t.role === 'assistant' && 'cacheWrite' in t);
  const labels = assistantTurns.map((_, i) => `T${{i+1}}`);

  const container = document.getElementById('tab-session');
  container.innerHTML = `
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-label">Total Tokens</div>
        <div class="stat-value blue">${{fmt(s.total_tokens)}}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">System Prompt (1st turn cacheWrite)</div>
        <div class="stat-value purple">${{fmt(s.system_prompt_tokens)}}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Cache Read</div>
        <div class="stat-value green">${{fmt(s.total_cache_read)}}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Output</div>
        <div class="stat-value orange">${{fmt(s.total_output)}}</div>
      </div>
    </div>
    <div class="section">
      <h2>Token Usage Per Turn (assistant messages)</h2>
      <div class="chart-container">
        <canvas id="turn-chart"></canvas>
      </div>
    </div>
    <div class="section">
      <h2>All Messages</h2>
      <table>
        <thead>
          <tr>
            <th>#</th><th>Role</th><th>Types</th><th>Preview</th>
            <th>Input</th><th>CacheRead</th><th>CacheWrite</th><th>Output</th><th>Total</th>
          </tr>
        </thead>
        <tbody id="turns-tbody"></tbody>
      </table>
    </div>
  `;

  const tbody = document.getElementById('turns-tbody');
  s.turns.forEach((t, i) => {{
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${{i+1}}</td>
      <td class="${{roleClass(t.role)}}">${{t.role}}</td>
      <td>${{(t.types||[]).join(', ')}}</td>
      <td style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:#888" title="${{(t.preview||'').replace(/"/g,'&quot;')}}">${{t.preview||''}}</td>
      <td>${{'input' in t ? fmt(t.input) : ''}}</td>
      <td style="color:#4ade80">${{'cacheRead' in t ? fmt(t.cacheRead) : ''}}</td>
      <td style="color:#a78bfa">${{'cacheWrite' in t ? fmt(t.cacheWrite) : ''}}</td>
      <td style="color:#fb923c">${{'output' in t ? fmt(t.output) : ''}}</td>
      <td style="font-weight:600">${{'total' in t ? fmt(t.total) : ''}}</td>
    `;
    tbody.appendChild(tr);
  }});

  // Chart
  if (turnChart) turnChart.destroy();
  const chartCanvas = document.getElementById('turn-chart');
  if (chartCanvas && assistantTurns.length > 0) {{
    turnChart = new Chart(chartCanvas, {{
      type: 'bar',
      data: {{
        labels,
        datasets: [
          {{ label: 'Input', data: assistantTurns.map(t => t.input||0), backgroundColor: '#3b82f6', stack: 'a' }},
          {{ label: 'CacheRead', data: assistantTurns.map(t => t.cacheRead||0), backgroundColor: '#22c55e', stack: 'a' }},
          {{ label: 'CacheWrite', data: assistantTurns.map(t => t.cacheWrite||0), backgroundColor: '#8b5cf6', stack: 'a' }},
          {{ label: 'Output', data: assistantTurns.map(t => t.output||0), backgroundColor: '#f97316', stack: 'a' }},
        ],
      }},
      options: {{
        responsive: true, maintainAspectRatio: false,
        plugins: {{ legend: {{ labels: {{ color: '#aaa', font: {{ size: 11 }} }} }} }},
        scales: {{
          x: {{ stacked: true, ticks: {{ color: '#666' }}, grid: {{ color: '#1e1e22' }} }},
          y: {{ stacked: true, ticks: {{ color: '#666', callback: v => fmt(v) }}, grid: {{ color: '#1e1e22' }} }},
        }},
      }},
    }});
  }}
}}

function renderContext() {{
  const components = ctx.components || [];
  const active = components.filter(c => !c.category.includes('disabled'));
  const total = active.reduce((s, c) => s + c.tokens, 0);
  const maxTokens = Math.max(...active.map(c => c.tokens), 1);

  const catColors = {{
    'project': '#fb923c',
    'skill-active': '#4ade80',
    'skill-disabled': '#333',
    'memory': '#a78bfa',
    'config': '#60a5fa',
  }};

  const container = document.getElementById('tab-context');
  container.innerHTML = `
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-label">Context Components Estimated</div>
        <div class="stat-value blue">${{fmt(total)}}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Tool Definitions (est.)</div>
        <div class="stat-value purple">~5k</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Active Skills</div>
        <div class="stat-value green">${{components.filter(c=>c.category==='skill-active').length}}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Disabled Skills</div>
        <div class="stat-value orange">${{components.filter(c=>c.category==='skill-disabled').length}}</div>
      </div>
    </div>
    <div class="section">
      <h2>Components (estimated tokens, descriptions only for skills)</h2>
      <table>
        <thead>
          <tr><th>Name</th><th>Category</th><th>Tokens</th><th style="width:200px">Visual</th><th>Preview</th></tr>
        </thead>
        <tbody>
          ${{components.map(c => `
            <tr>
              <td class="ctx-cat-${{c.category}}">${{c.name}}</td>
              <td style="color:#666;font-size:11px">${{c.category}}</td>
              <td style="font-weight:600">${{c.tokens}}</td>
              <td>
                <div class="bar"><div class="bar-fill" style="width:${{Math.round(c.tokens/maxTokens*100)}}%;background:${{catColors[c.category]||'#555'}}"></div></div>
              </td>
              <td style="max-width:280px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:#666;font-size:11px" title="${{(c.preview||'').replace(/"/g,'&quot;')}}">${{c.preview||''}}</td>
            </tr>
          `).join('')}}
        </tbody>
      </table>
      <p style="margin-top:12px;font-size:11px;color:#555">${{ctx.note||''}}</p>
    </div>
  `;
}}

function showTab(name) {{
  document.querySelectorAll('.tab').forEach((t,i) => t.classList.toggle('active', ['session','context'][i] === name));
  document.getElementById('tab-session').style.display = name === 'session' ? '' : 'none';
  document.getElementById('tab-context').style.display = name === 'context' ? '' : 'none';
  if (name === 'context') renderContext();
}}

// Select first session by default
if (sessions.length > 0) {{
  selectSession(0);
}} else {{
  document.getElementById('tab-session').innerHTML = '<p class="empty">No sessions found.</p>';
}}
</script>
</body>
</html>"""


def main():
    parser = argparse.ArgumentParser(description="Pi Token Analyzer")
    parser.add_argument("--html", action="store_true", help="Output HTML report")
    parser.add_argument("--json", action="store_true", help="Output JSON data")
    parser.add_argument("--context", action="store_true", help="Analyze context only")
    parser.add_argument("--limit", type=int, default=10, help="Sessions per project")
    parser.add_argument("--open", action="store_true", help="Open HTML in browser")
    args = parser.parse_args()

    sessions = load_all_sessions(limit_per_project=args.limit)
    context = analyze_context()

    if args.context:
        print(json.dumps(context, indent=2, ensure_ascii=False))
        return

    if args.json:
        print(json.dumps({"sessions": sessions, "context": context}, indent=2, ensure_ascii=False))
        return

    if args.html or args.open:
        html = generate_html(sessions, context)
        out = Path("/tmp/pi-token-analyzer.html")
        out.write_text(html)
        print(f"Written to {out}", file=sys.stderr)
        if args.open:
            os.system(f"open {out}")
        else:
            print(html)
        return

    def fmt(n: int) -> str:
        if n >= 1_000_000: return f"{n/1_000_000:.1f}M"
        if n >= 1_000: return f"{n/1_000:.1f}k"
        return str(n)

    # Default: print summary table
    print(f"{'Project':<40} {'Date':<22} {'SysPrompt':>10} {'TotalTok':>10} {'Turns':>6}")
    print("-" * 92)
    for s in sessions[:30]:
        proj = s['project'].split('/')[-1][:38]
        ts = s['timestamp'][:19].replace('T', ' ')
        print(f"{proj:<40} {ts:<22} {fmt(s['system_prompt_tokens']):>10} {fmt(s['total_tokens']):>10} {len([t for t in s['turns'] if t['role']=='assistant']):>6}")

if __name__ == "__main__":
    main()
