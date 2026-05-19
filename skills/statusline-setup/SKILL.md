---
name: Statusline Setup
description: This skill should be used when the user asks to "set up the status bar", "configure statusline", "install claude-statusline", "enable the status bar", "how do I use claude-statusline", or wants to point Claude Code to the statusline script. Guides through the one-time configuration of the statusline command in Claude Code settings.
version: 0.1.0
---

# Statusline Setup

The `claude-statusline` plugin provides a two-line status bar for Claude Code:

```
🤖 claude-sonnet-4.6  🧠  [██░░░░░░░░] 12% · 24.3k/200k  🎯 42.1%
📁 my-project  🌿 main ±3 ⬆1  🔧 4 MCP  📦 30 Skills
```

**Line 1** — conversation state: model, thinking mode, context progress bar, cache hit rate  
**Line 2** — environment: working directory, git branch/dirty/unpushed, MCP count, Skills count

## One-Time Configuration

To activate the status bar, set the `statusLine` field in `~/.claude/settings.json` to point to the script shipped with this plugin.

### Step 1 — Find the script path

The script is located at:

```
$CLAUDE_PLUGIN_ROOT/scripts/statusline-command.sh
```

To resolve the actual path, run:

```bash
ls ~/.claude/plugins/cache/*/claude-statusline/scripts/statusline-command.sh 2>/dev/null \
  || find ~/.claude/plugins -name statusline-command.sh 2>/dev/null
```

### Step 2 — Add to settings.json

Open `~/.claude/settings.json` and add (or merge) the `statusLine` block:

```json
{
  "statusLine": {
    "command": "/absolute/path/to/statusline-command.sh"
  }
}
```

Replace `/absolute/path/to/statusline-command.sh` with the path found in Step 1.

**Windows example** (Git Bash path):
```json
{
  "statusLine": {
    "command": "C:/Users/yourname/.claude/plugins/cache/yidasanqian/claude-statusline/scripts/statusline-command.sh"
  }
}
```

**Linux/macOS example**:
```json
{
  "statusLine": {
    "command": "/home/yourname/.claude/plugins/cache/yidasanqian/claude-statusline/scripts/statusline-command.sh"
  }
}
```

### Step 3 — Verify

Restart Claude Code (or start a new session). The status bar should appear at the top of the prompt area showing two lines of information.

## What Each Field Shows

| Element | Description |
|---------|-------------|
| `🤖 model` | Active Claude model ID |
| `🧠` | Thinking mode (only shown when enabled) |
| `[████░░░░░░] N%` | Context window usage as 10-block progress bar |
| `used/total` | Absolute token counts in thousands |
| `🎯 N%` | Cache hit rate (hidden when 0%) |
| `📁 dir` | Working directory basename |
| `🌿 branch` | Git branch (hidden in non-git directories) |
| `±N` | Uncommitted file count (hidden when 0) |
| `⬆N` | Unpushed commit count (hidden when 0) |
| `🔧 N MCP` | Number of active MCP servers |
| `📦 N Skills` | Number of loaded skills |

## Requirements

- `bash` (Git Bash on Windows, or native bash on Linux/macOS)
- `jq` — JSON parsing (`brew install jq` / `apt install jq` / `winget install jqlang.jq`)
- `node` — skills and MCP counting
- `git` — git status fields (optional; git fields hidden if not in a repo)

## Troubleshooting

**Status bar not appearing**: Confirm the path in `settings.json` points to an executable file. Run `chmod +x /path/to/statusline-command.sh` if needed on Linux/macOS.

**`jq: command not found`**: Install jq — it is the only mandatory external dependency.

**All fields show empty**: Verify Claude Code is passing JSON to the script. Test manually:
```bash
echo '{}' | bash /path/to/statusline-command.sh
```

**Skills count shows 0**: Ensure the plugin is enabled in Claude Code and `node` is available on `$PATH`.
