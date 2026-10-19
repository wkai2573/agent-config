# agent-config

我的 Claude Code 與 Gemini（Antigravity）全域設定備份（skills、AGENTS.md、memory、mods 等），附一鍵同步腳本。只處理全域設定，專案獨立的內容不在範圍內。

## 內容

| 路徑 | 同步到 | 方式 |
| --- | --- | --- |
| `skills/` | `~/.claude/skills/<名稱>` | 連結（13 個自訂 skills） |
| `config/AGENTS.md` | `~/AGENTS.md` | 複製 |
| `config/GEMINI.md` | `~/GEMINI.md` | 複製 |
| `config/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | 複製 |
| `config/claude/settings.json` | `~/.claude/settings.json` | 複製 |
| `memory/` | `~/.claude/projects/<家目錄編碼>/memory` | 連結 |
| `agents/` | `~/.claude/agents` | 連結（自訂 subagent，目前有 `mechanical-check`） |
| `mods/<名稱>/` | `~/.claude/dev-mods/synced/<名稱>` | 連結 |
| `gemini/skills.json` | `~/.gemini/config/skills.json` | 參考（腳本會補上指向 `~/.claude/skills` 的設定） |
| `install.ps1` / `install.sh` | | 新電腦安裝 |
| `export.ps1` | | 原始電腦用：把本機改過的內容複製回 repo |

不收錄：`synced/`（Claude 官方雲端同步的 skills，登入帳號會自動出現）、`.trash/`。
`generate-image` 在 Gemini 端被排除（Gemini 自己會生圖，這個 skill 只給 Claude 用）。

## 在新電腦同步（Windows）

```powershell
git clone https://github.com/wkai2573/agent-config.git $HOME\agent-config
& $HOME\agent-config\install.ps1
```

## 在新電腦同步（macOS / Linux / WSL）

```bash
git clone https://github.com/wkai2573/agent-config.git ~/agent-config
bash ~/agent-config/install.sh
```

腳本做的事：

1. 把 `skills/*` 每個資料夾連結（Windows 用 junction，不需管理員權限）到 `~/.claude/skills/`。
2. 若該位置已有同名真實資料夾，先備份到 `~/.claude/skills-backup/`，不會直接覆蓋。
3. 把 `config/` 的設定檔複製到家目錄；內容不同時，舊檔先備份到 `~/.claude/config-backup/`。
4. 把 `memory/` 連結成家目錄專案的 memory，`agents/` 連結到 `~/.claude/agents`，`mods/*` 連結到 `~/.claude/dev-mods/synced/`（既有的非空資料夾一樣先備份）。
5. 若有安裝 Gemini，在 `~/.gemini/config/skills.json` 補上指向 `~/.claude/skills` 的設定（已有就不動）。

可重複執行；重開 Claude Code / Gemini 後生效。

## 日常同步設定

先記住一個分別：skills、memory、agents、mods 是**連結**，改本機就等於改 repo；`AGENTS.md`、`GEMINI.md`、`CLAUDE.md`、`settings.json` 是**複製**，要靠腳本搬。

### 1. 在這台電腦改了設定，推上去

```powershell
cd $HOME\agent-config                  # 或你 clone 的位置
.\export.ps1                     # 把本機的設定檔、skills、memory、agents、mods 複製回 repo
git add -A; git commit -m "更新全域設定"; git push
```

- 只改了連結型的內容（skills、memory、agents、mods）且這台已跑過 `install`：不用 `export.ps1`，直接 commit / push。
- 改了設定檔：一定要先跑 `export.ps1`，否則 repo 裡還是舊的。

### 2. 在另一台電腦取得最新設定

```powershell
git -C $HOME\agent-config pull
& $HOME\agent-config\install.ps1       # macOS / Linux 用 bash ~/agent-config/install.sh
```

- 連結型的內容 pull 完就生效；設定檔要重跑 install 才會複製過去。
- 重跑 install 是安全的：內容相同就略過，不同就先備份到 `~/.claude/config-backup/` 再覆蓋。
- 重開 Claude Code / Gemini 後生效。

### 3. 要遵守的順序

同一份設定檔不要在兩台電腦各改各的。標準流程是：改完 → `export.ps1` → push → 另一台 pull → install。若另一台已經有未上傳的修改就先跑 install，那些修改會被 repo 版本覆蓋，只能到 `~/.claude/config-backup/` 找回。

## 注意

- **memory**：Claude Code 的 memory 本來就是依專案分開存放，沒有真正的全域 memory，這裡只同步在家目錄開啟 Claude Code 時用的那一份。其餘專案的 memory 不同步。
- **agents**：放的是 subagent 定義檔，不是 skill，所以不會出現在 `/my-skills` 清單。`mechanical-check` 固定用 Haiku 跑測試、型別檢查、lint，只回報不修改，搭配 `config/claude/CLAUDE.md` 裡的「檢查委派」規則讓 Claude 自動委派。
- **mods**：`export.ps1` 會從 `~/.claude/dev-mods/*/` 收集含 `.claude-plugin/plugin.json` 的 mod（排除引擎產生的 `types/`）。連結後的 mod 位於 `~/.claude/dev-mods/synced/`，在新電腦要用 `claude --plugin-dir` 指到該資料夾載入。
- **settings.json**：若內含外部工具自動寫入、寫死本機路徑的 hooks，跨電腦會失效；同步前先確認內容是通用的。
- 新增 skill：在 `skills/` 下建資料夾（含 `SKILL.md`），重跑一次 `install` 才會建立連結。
- 這是私有 repo；若要改公開，先確認 skills 內沒有私人資訊。
