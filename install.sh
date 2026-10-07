#!/usr/bin/env bash
# 把本 repo 的 skills 以符號連結裝到 Claude Code / Gemini（Antigravity）。
# 之後只要 git pull，兩邊的 skills 就一起更新。可重複執行。
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_dir="${CLAUDE_DIR:-$HOME/.claude/skills}"
gemini_cfg="${GEMINI_CONFIG:-$HOME/.gemini/config/skills.json}"
backup_dir="${BACKUP_DIR:-$HOME/.claude/skills-backup}"

mkdir -p "$claude_dir"

for d in "$repo"/skills/*/; do
  name="$(basename "$d")"
  link="$claude_dir/$name"
  if [ -L "$link" ]; then
    rm "$link"
  elif [ -e "$link" ]; then
    mkdir -p "$backup_dir"
    bak="$backup_dir/$name.$(date +%Y%m%d%H%M%S)"
    mv "$link" "$bak"
    echo "  已備份既有的 $name -> $bak"
  fi
  ln -s "${d%/}" "$link"
  echo "  已連結 $name"
done

# 全域設定檔：以「複製」方式放到家目錄；內容不同時，先把舊檔備份再覆蓋
cfg_backup="$HOME/.claude/config-backup"
copy_config() {
  local from="$repo/$1" to="$2"
  [ -f "$from" ] || return 0
  if [ -f "$to" ]; then
    cmp -s "$from" "$to" && return 0
    mkdir -p "$cfg_backup"
    cp "$to" "$cfg_backup/$(basename "$to").$(date +%Y%m%d%H%M%S)"
    echo "  已備份既有的 $(basename "$to") -> $cfg_backup"
  fi
  mkdir -p "$(dirname "$to")"
  cp "$from" "$to"
  echo "  已更新 $(basename "$to")"
}
copy_config config/AGENTS.md "$HOME/AGENTS.md"
copy_config config/GEMINI.md "$HOME/GEMINI.md"
copy_config config/claude/CLAUDE.md "$HOME/.claude/CLAUDE.md"
copy_config config/claude/settings.json "$HOME/.claude/settings.json"

# 以符號連結同步的資料夾：memory（家目錄專案的）與 mods
link_dir() {
  local target="$1" link="$2"
  mkdir -p "$(dirname "$link")"
  if [ -L "$link" ]; then
    rm "$link"
  elif [ -d "$link" ]; then
    if [ -z "$(ls -A "$link")" ]; then
      rmdir "$link"
    else
      mkdir -p "$cfg_backup"
      mv "$link" "$cfg_backup/$(basename "$link").$(date +%Y%m%d%H%M%S)"
      echo "  已備份既有的 $link -> $cfg_backup"
    fi
  fi
  ln -s "$target" "$link"
}

# memory：Claude Code 以專案路徑編碼成資料夾名（非英數字元換成 -），這裡只處理家目錄那一個
home_project="$(printf '%s' "$HOME" | sed 's/[^A-Za-z0-9]/-/g')"
mem_link="$HOME/.claude/projects/$home_project/memory"
link_dir "$repo/memory" "$mem_link"
echo "  已連結 memory -> $mem_link"

# mods：每個子資料夾連結到 ~/.claude/dev-mods/synced/<名稱>
for d in "$repo"/mods/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  link_dir "${d%/}" "$HOME/.claude/dev-mods/synced/$name"
  echo "  已連結 mod $name"
done

# Gemini（Antigravity）：讓它也讀 ~/.claude/skills
if [ ! -d "$(dirname "$gemini_cfg")" ]; then
  echo "（找不到 $(dirname "$gemini_cfg")，略過 Gemini 設定；之後安裝 Gemini 再重跑本腳本即可）"
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$gemini_cfg" "$claude_dir" <<'PY'
import json, os, sys
cfg, claude = sys.argv[1], sys.argv[2]
data = json.load(open(cfg, encoding="utf-8")) if os.path.exists(cfg) else {"entries": []}
if any(e.get("path") == claude for e in data.get("entries", [])):
    print(f"  Gemini 設定已包含 {claude}，不需變更")
else:
    data.setdefault("entries", []).append({"path": claude, "exclude": ["synced", "generate-image"]})
    with open(cfg, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"  已在 Gemini 設定加入 {claude}")
PY
else
  echo "（找不到 python3，請手動在 $gemini_cfg 的 entries 加入 {\"path\": \"$claude_dir\", \"exclude\": [\"synced\", \"generate-image\"]}）"
fi
echo "完成。重開 Claude Code / Gemini 即可看到 skills。"
