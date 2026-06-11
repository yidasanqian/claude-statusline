#!/usr/bin/env bash
# Claude Code statusLine command script
# Reads JSON from stdin, outputs two-line status
# Compatible with Windows (Git Bash / Cygwin / MSYS2) and Linux/Unix

OS="$(uname -s 2>/dev/null)"
IS_WINDOWS=false
[[ "$OS" == CYGWIN* || "$OS" == MINGW* || "$OS" == MSYS* ]] && IS_WINDOWS=true

input=$(cat)

model=$(echo "$input" | jq -r 'if .model | type == "object" then .model.id else (.model // empty) end')
effort=$(echo "$input" | jq -r '.effort.level // empty')
thinking=$(echo "$input" | jq -r '.thinking.enabled // false')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cws=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
inp=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
out=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
cc=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cr=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

used=$(awk "BEGIN{printf \"%.0f\", $inp+$out+$cc+$cr}")

# Message count from transcript (user + assistant roles)
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
msg_count=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  count=$(grep -c '"role"' "$transcript" 2>/dev/null || echo 0)
  [ "$count" -gt 0 ] && msg_count="💬 ${count}"
fi

# Git branch (needed for line 1 and line 2)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Line 1: 🤖 model  [🧠]  [██░░░░░░░░] pct% · used/total  🎯 cache%

# Model with robot icon
modelstr="🤖 ${model}"

# Thinking flag (only when enabled)
thinkstr=""
[ "$thinking" = "true" ] && thinkstr="🧠"

# Context: 10-block progress bar + pct% · used/total
ctxstr=""
if [ -n "$pct" ] && [ "$pct" != "null" ]; then
  filled=$(awk "BEGIN{n=int($pct/10+0.5); if(n>10)n=10; print n}")
  bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then bar="${bar}█"; else bar="${bar}░"; fi
  done
  pct_int=$(printf "%.0f" "$pct")
  used_k=$(awk "BEGIN{printf \"%.1f\", $used/1000}")
  total_k=$(awk "BEGIN{printf \"%.1f\", $cws/1000}")
  ctxstr="[${bar}] ${pct_int}% · ${used_k}k/${total_k}k"
fi

# Cache hit rate (1 decimal)
hitstr=""
denom=$(awk "BEGIN{print $inp+$cc+$cr}")
if awk "BEGIN{exit !($cr > 0)}"; then
  hitp=$(awk "BEGIN{printf \"%.1f\", $cr/($denom)*100}")
  hitstr="🎯 ${hitp}%"
fi

# Assemble line 1 — two spaces between groups, skip empty parts
line1=""
for part in "$modelstr" "$thinkstr" "$ctxstr" "$hitstr" "$msg_count"; do
  [ -z "$part" ] && continue
  [ -z "$line1" ] && line1="$part" || line1="${line1}  ${part}"
done
printf "%s\n" "$line1"

# MCP server count — use forward slashes to avoid backslash escape issues in JS strings
if $IS_WINDOWS; then
  home_fwd=$(cygpath -u "${USERPROFILE:-$HOME}" 2>/dev/null || echo "${USERPROFILE:-$HOME}")
else
  home_fwd="$HOME"
fi
home_fwd="${home_fwd%/}"
settings_path="${home_fwd}/.claude/settings.json"
claude_json_path="${home_fwd}/.claude.json"

# Also check project-level settings.json inside ~/.claude/projects/<slug>/settings.json
# Claude Code slug: replace backslashes, colons, and forward-slashes each with '-'
if $IS_WINDOWS; then
  proj_slug=$(echo "${cwd}" | sed 's|[/\\]|-|g; s|:|-|g')
else
  proj_slug=$(echo "${cwd}" | sed 's|/|-|g')
fi
proj_settings="${home_fwd}/.claude/projects/${proj_slug}/settings.json"

mcp_n=$(node -e "
var fs = require('fs');
var g = {};
var u = {};
var p = {};
var ps = {};
try { g = JSON.parse(fs.readFileSync(process.argv[1], 'utf8')).mcpServers || {}; } catch(e) {}
try { u = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).mcpServers || {}; } catch(e) {}
try { p = JSON.parse(fs.readFileSync(process.argv[3], 'utf8')).mcpServers || {}; } catch(e) {}
try { ps = JSON.parse(fs.readFileSync(process.argv[4], 'utf8')).mcpServers || {}; } catch(e) {}
var merged = Object.assign({}, g, u, ps, p);
console.log(Object.keys(merged).length);
" "$settings_path" "$claude_json_path" "${cwd}/.mcp.json" "$proj_settings" 2>/dev/null || echo 0)

# Skills count: user skills = subdirs in ~/.claude/skills/
#               plugin skills = SKILL.md under installPaths of enabled plugins only
user_skills=$(ls -d "${home_fwd}/.claude/skills"/*/ 2>/dev/null | wc -l)
plugin_skills=$(node -e "
var fs = require('fs'), path = require('path');
var home = process.argv[1];
var enabled = {};
var installed = {};
try { enabled = JSON.parse(fs.readFileSync(home+'/.claude/settings.json','utf8')).enabledPlugins || {}; } catch(e){}
try { installed = JSON.parse(fs.readFileSync(home+'/.claude/plugins/installed_plugins.json','utf8')).plugins || {}; } catch(e){}
var count = 0;
Object.keys(enabled).filter(function(k){ return enabled[k]; }).forEach(function(k){
  var entries = installed[k];
  if (!entries || !entries.length) return;
  var p = entries[entries.length-1].installPath.replace(/\\\\/g,'/');
  try {
    count += (function walk(d){
      var n=0;
      fs.readdirSync(d).forEach(function(f){
        var fp=d+'/'+f;
        if(fs.statSync(fp).isDirectory()) n+=walk(fp);
        else if(f==='SKILL.md') n++;
      });
      return n;
    })(p);
  } catch(e){}
});
console.log(count);
" "$home_fwd" 2>/dev/null || echo 0)

# Also check .claude.json for skills array length as a fallback
claude_json_skills=$(node -e "
var fs = require('fs');
var home = process.argv[1];
try {
  var data = JSON.parse(fs.readFileSync(home+'/.claude.json','utf8'));
  var skills = data.skills || data.installedSkills || [];
  console.log(Array.isArray(skills) ? skills.length : Object.keys(skills).length);
} catch(e) { console.log(0); }
" "$home_fwd" 2>/dev/null || echo 0)

# Use whichever source reports more skills
if [ "$claude_json_skills" -gt "$((user_skills + plugin_skills))" ] 2>/dev/null; then
  skills_n=$claude_json_skills
else
  skills_n=$(( user_skills + plugin_skills ))
fi

# Line 2: 📁 dir  🌿 branch ±dirty ⬆unpushed  🔧 N MCP  📦 N Skills

# Working dir basename
dir_name=""
[ -n "$cwd" ] && dir_name=$(basename "$cwd")

# Git dirty count
git_dirty=""
if [ -n "$cwd" ] && [ -n "$branch" ]; then
  dirty_count=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [ -n "$dirty_count" ] && [ "$dirty_count" -gt 0 ] 2>/dev/null && git_dirty="±${dirty_count}"
fi

# Git unpushed commits count
git_unpushed=""
if [ -n "$cwd" ] && [ -n "$branch" ]; then
  unpushed=$(git -C "$cwd" --no-optional-locks rev-list --count @{u}..HEAD 2>/dev/null)
  [ -n "$unpushed" ] && [ "$unpushed" -gt 0 ] 2>/dev/null && git_unpushed="⬆${unpushed}"
fi

# Git block: only shown in git repos, no brackets
git_block=""
if [ -n "$branch" ]; then
  git_block="🌿 ${branch}"
  [ -n "$git_dirty" ]    && git_block="${git_block} ${git_dirty}"
  [ -n "$git_unpushed" ] && git_block="${git_block} ${git_unpushed}"
fi

# Assemble line 2 — two spaces between groups
line2=""
dir_part=""
[ -n "$dir_name" ] && dir_part="📁 ${dir_name}"
for part in "$dir_part" "$git_block" "🔧 ${mcp_n} MCP" "📦 ${skills_n} Skills"; do
  [ -z "$part" ] && continue
  [ -z "$line2" ] && line2="$part" || line2="${line2}  ${part}"
done
printf "%s" "$line2"
