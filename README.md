# claude-statusline

A two-line status bar plugin for [Claude Code](https://claude.ai/code) that shows model info, context usage, cache hit rate, git status, MCP servers, and skills count.

```
🤖 claude-sonnet-4.6  🧠  [██░░░░░░░░] 12% · 24.3k/200k  🎯 42.1%
📁 my-project  🌿 main ±3 ⬆1  🔧 4 MCP  📦 30 Skills
```

## Features

- **Line 1** — Model name, thinking mode indicator, context window progress bar with token counts, cache hit rate
- **Line 2** — Working directory, git branch + dirty/unpushed counts, MCP server count, Skills count
- **Cross-platform** — Works on Windows (Git Bash / MSYS2 / Cygwin) and Linux/macOS
- **Zero noise** — Fields hide automatically when empty (no git repo, no unpushed commits, etc.)

## Requirements

- [Claude Code](https://claude.ai/code) with status bar support
- `bash` (Git Bash on Windows, native bash on Linux/macOS)
- `jq` — JSON parsing
- `node` — skills and MCP counting
- `git` — git fields (optional)

Install jq:
```bash
# macOS
brew install jq
# Ubuntu/Debian
apt install jq
# Windows (winget)
winget install jqlang.jq
```

## Installation

### Via Claude Code (recommended)

**Step 1** — Add the marketplace:

```
/plugin marketplace add yidasanqian/claude-statusline
```

**Step 2** — Install the plugin:

```
/plugin install claude-statusline@claude-statusline
```

Or with the CLI (non-interactive):

```bash
claude plugin marketplace add yidasanqian/claude-statusline
claude plugin install claude-statusline@claude-statusline
```

### Manual Installation (Git Clone)

```bash
git clone https://github.com/yidasanqian/claude-statusline \
  ~/.claude/plugins/cache/yidasanqian/claude-statusline
```

### After Installing

Run `/claude-statusline:statusline-setup` in Claude Code and follow the configuration steps, or see [Configuration](#configuration) below.

## Configuration

Add the `statusLine` field to `~/.claude/settings.json`:

**Linux/macOS:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/plugins/cache/yidasanqian/claude-statusline/scripts/statusline-command.sh"
  }
}
```

**Windows (Git Bash):**
```json
{
  "statusLine": {
    "type": "command",
    "command": "C:/Users/yourname/.claude/plugins/cache/yidasanqian/claude-statusline/scripts/statusline-command.sh"
  }
}
```

Restart Claude Code to apply.

## Status Bar Reference

| Element | Description |
|---------|-------------|
| `🤖 model` | Active Claude model ID |
| `🧠` | Thinking mode (shown only when enabled) |
| `[████░░░░░░] N%` | Context window usage (10-block progress bar) |
| `used/total` | Token counts in thousands |
| `🎯 N%` | Cache hit rate (hidden when 0%) |
| `📁 dir` | Working directory basename |
| `🌿 branch` | Git branch (hidden outside git repos) |
| `±N` | Uncommitted file count (hidden when 0) |
| `⬆N` | Unpushed commit count (hidden when 0) |
| `🔧 N MCP` | Active MCP server count |
| `📦 N Skills` | Loaded skills count |

## License

MIT
