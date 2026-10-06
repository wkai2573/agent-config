---
name: setup-matt-pocock-skills
description: "為工程 skills 設定這個倉庫：建立它的議題追蹤系統、分流標籤詞彙，以及領域文件佈局。在第一次使用其他工程 skills 之前執行一次。"
disable-model-invocation: true
---

# 設定 Matt Pocock 的 Skills

建立工程 skills 所假設的、每個倉庫各自的設定：

- **議題追蹤系統**：議題放在哪裡（預設為 GitHub；也內建支援本地 markdown）
- **分流標籤**：五個標準分流角色所使用的字串
- **領域文件**：`GLOSSARY.md` 和 ADR 放在哪裡，以及讀取它們的消費規則

這是一個由提示驅動的 skill，不是確定性的腳本。探索、呈現你發現的內容、與使用者確認，然後才寫入。

## 流程

### 1. 探索

查看目前的倉庫，了解它的起始狀態。讀取現有的東西；不要假設：

- `git remote -v` 與 `.git/config`：這是 GitHub 倉庫嗎？是哪一個？
- 倉庫根目錄的 `AGENTS.md` 與 `CLAUDE.md`：哪一個存在？其中是否已經有 `## Agent skills` 章節？
- 倉庫根目錄的 `GLOSSARY.md` 與 `GLOSSARY-MAP.md`
- `docs/adr/` 以及任何 `src/*/docs/adr/` 目錄
- `docs/agents/`：這個 skill 先前的輸出是否已經存在？
- `.scratch/`：表示已經在使用本地 markdown 議題追蹤慣例的跡象
- 是否已安裝 `triage` skill？（在這個 skill 旁邊有 `triage` skill 資料夾，或你可用的 skills 中有 `triage`。）這決定了 B 區段是否要執行。
- Monorepo 的跡象：`pnpm-workspace.yaml`、`package.json` 中的 `workspaces` 欄位，或是有內容、各自帶有 `src/` 的 `packages/*`。這些只會出現在真正龐大的多套件倉庫；沒有它們就代表單一情境，幾乎每個倉庫都是如此。

### 2. 呈現發現並詢問

摘要說明哪些已存在、哪些缺少。然後依序處理各個區段。一個區段、一個答案，再下一個。

每個區段都以建議的答案開頭，讓使用者一個詞就能接受。只有在選擇真的有分歧時，才給一行說明；當探索已經決定了答案，就整個跳過該區段（`triage` 未安裝時跳過 B 區段，沒有 monorepo 時跳過 C 區段）。

**A 區段：議題追蹤系統。**

**這個使用者不熟遠端，預設一律使用「本地 markdown」，不要詢問、不要因為偵測到 GitHub 或 GitLab 的 `git remote` 就改選它們。** 直接記錄為本地 markdown 並進入下一個區段。只有在使用者明確說要用 GitHub、GitLab 或其他系統時，才依下方的選項處理。

> 說明：「議題追蹤系統」是這個倉庫的議題所在之處。像 `to-tickets`、`triage` 和 `to-spec` 這樣的 skills 會從中讀取與寫入。它們需要知道該呼叫 `gh issue create`、在 `.scratch/` 底下寫一個 markdown 檔案，還是遵循你描述的其他工作流程。挑選你實際上用來追蹤這個倉庫工作的地方。

預設立場：這些 skills 是為 GitHub 設計的。如果某個 `git remote` 指向 GitHub，就提議它。如果某個 `git remote` 指向 GitLab（`gitlab.com` 或自行架設的主機），就提議 GitLab。否則（或使用者偏好的話），提供：

- **GitHub**：議題放在倉庫的 GitHub Issues（使用 `gh` CLI）
- **GitLab**：議題放在倉庫的 GitLab Issues（使用 [`glab`](https://gitlab.com/gitlab-org/cli) CLI）
- **本地 markdown**：議題以檔案形式放在這個倉庫的 `.scratch/<feature>/` 底下（適合個人專案或沒有 remote 的倉庫）
- **其他**（Jira、Linear 等）：請使用者用一段話描述工作流程；skill 會把它記錄成自由格式的文字

把選擇記錄在 `docs/agents/issue-tracker.md`。GitHub 與 GitLab 的模板帶有一個「PR 作為需求入口」旗標，預設為**關閉**。保持關閉，也不要提起它：想把外部 PR 放進分流佇列的使用者，之後可以在檔案中自己切換旗標。

**B 區段：分流標籤詞彙。** 如果 `triage` skill 沒有安裝（探索時就會知道），就完全跳過這個區段，因為沒安裝的 skill 不需要標籤。

如果已安裝，就只問一個問題：

> 你要保留預設的分流標籤嗎？（建議：**是**）

預設是五個標準角色，每個標籤字串都等於它的名稱：`needs-triage`、`needs-info`、`ready-for-agent`、`ready-for-human`、`wontfix`。回答**是**時，原樣寫入。只有在使用者回答否時（通常是因為他們的追蹤系統已經使用其他名稱，例如用 `bug:triage` 代表 `needs-triage`），才蒐集覆寫設定，讓 `triage` 套用既有標籤，而不是建立重複的。

**C 區段：領域文件。** 預設為**單一情境**（倉庫根目錄一份 `GLOSSARY.md` + `docs/adr/`）。這適合幾乎每個倉庫；不用詢問，直接寫入。

只有在探索發現 monorepo 的跡象時，才提供**多情境**（根目錄的 `GLOSSARY-MAP.md` 指向各情境的 `GLOSSARY.md` 檔案）。然後確認他們想要哪種佈局。

### 3. 確認與編輯

向使用者展示以下內容的草稿：

- 要加入 `CLAUDE.md` / `AGENTS.md` 其中一個（視要編輯哪一個而定，選擇規則見步驟 4）的 `## Agent skills` 區塊
- `docs/agents/issue-tracker.md`、`docs/agents/domain.md` 和 `docs/agents/triage-labels.md` 的內容（最後一個僅在 `triage` 已安裝時才有）

在寫入之前，讓他們先編輯。

### 4. 寫入

**挑選要編輯的檔案：**

- 如果 `CLAUDE.md` 存在，就編輯它。
- 否則如果 `AGENTS.md` 存在，就編輯它。
- 如果兩者都不存在，就詢問使用者要建立哪一個；不要替他們挑。

當 `CLAUDE.md` 已經存在時，絕不建立 `AGENTS.md`（反之亦然）；一律編輯已經在那裡的那一個。

如果所選檔案中已存在 `## Agent skills` 區塊，就就地更新它的內容，而不是附加重複的區塊。不要覆寫使用者對周圍章節所做的編輯。

區塊如下：

```markdown
## Agent skills

### 議題追蹤系統

[議題追蹤位置的一行摘要]。請見 `docs/agents/issue-tracker.md`。

### 分流標籤

[標籤詞彙的一行摘要]。請見 `docs/agents/triage-labels.md`。

### 領域文件

[佈局的一行摘要：「單一情境」或「多情境」]。請見 `docs/agents/domain.md`。
```

只有在 `triage` 已安裝且 B 區段有執行時，才包含 `### 分流標籤` 子區塊並寫入 `docs/agents/triage-labels.md`。若非如此，兩者都省略。

然後以這個 skill 資料夾中的種子模板為起點，寫入文件檔案：

- [issue-tracker-github.md](./issue-tracker-github.md)：GitHub 議題追蹤系統
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md)：GitLab 議題追蹤系統
- [issue-tracker-local.md](./issue-tracker-local.md)：本地 markdown 議題追蹤系統
- [triage-labels.md](./triage-labels.md)：標籤對應（僅在 `triage` 已安裝時）
- [domain.md](./domain.md)：領域文件消費規則 + 佈局

針對「其他」議題追蹤系統，依使用者的描述從頭撰寫 `docs/agents/issue-tracker.md`。

### 5. 完成

告訴使用者設定已完成，以及現在哪些工程 skills 會從這些檔案讀取。提醒他們之後可以直接編輯 `docs/agents/*.md`；只有在想切換議題追蹤系統或從頭開始時，才需要重新執行這個 skill。
