# 議題追蹤系統：GitHub

這個倉庫的議題與規格以 GitHub 議題的形式存在。所有操作都使用 `gh` CLI。

## 慣例

- **建立議題**：`gh issue create --title "..." --body "..."`。多行內文使用 heredoc。
- **讀取議題**：`gh issue view <number> --comments`，以 `jq` 篩選留言，並同時取得標籤。
- **列出議題**：`gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'`，並搭配適當的 `--label` 與 `--state` 篩選。
- **在議題上留言**：`gh issue comment <number> --body "..."`
- **套用／移除標籤**：`gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **關閉**：`gh issue close <number> --comment "..."`

從 `git remote -v` 推斷倉庫；在 clone 內執行時，`gh` 會自動這樣做。

## 將 Pull Request 視為分流入口

**PR 作為需求入口：否。** _（如果這個倉庫把外部 PR 視為功能需求，就設為 `yes`；`/triage` 會讀取這個旗標。）_

設為 `yes` 時，PR 會與議題走過相同的標籤與狀態，使用對應的 `gh pr` 指令：

- **讀取 PR**：`gh pr view <number> --comments`，以及用 `gh pr diff <number>` 取得 diff。
- **列出待分流的外部 PR**：`gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments`，然後只保留 `authorAssociation` 為 `CONTRIBUTOR`、`FIRST_TIME_CONTRIBUTOR` 或 `NONE` 的（排除 `OWNER`/`MEMBER`/`COLLABORATOR`）。
- **留言／標籤／關閉**：`gh pr comment`、`gh pr edit --add-label`/`--remove-label`、`gh pr close`。

GitHub 讓議題與 PR 共用同一個編號空間，所以單純的 `#42` 可能是兩者之一：先用 `gh pr view 42` 解析，失敗再退回 `gh issue view 42`。

## 當 skill 說「發佈到議題追蹤系統」

建立一個 GitHub 議題。

## 當 skill 說「取得相關票券」

執行 `gh issue view <number> --comments`。

## 尋路操作（Wayfinding operations）

由 `/wayfinder` 使用。**地圖**是單一議題，**子**議題就是票券。

- **地圖**：標上 `wayfinder:map` 標籤的單一議題，內文包含備註／目前已做的決策／迷霧。`gh issue create --label wayfinder:map`。
- **子票券**：以 GitHub 子議題（sub-issue）連結到地圖的議題（對子議題端點使用 `gh api`）。若未啟用子議題，就把子議題加到地圖內文的任務清單中，並在子議題內文最上方放 `Part of #<map>`。標籤：`wayfinder:<type>`（`research`/`prototype`/`grilling`/`task`）。一旦被領取，票券就指派給推動的開發者。
- **阻擋**：GitHub 的**原生議題相依關係**，是標準且在 UI 中可見的表示方式。以 `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>` 新增一條邊，其中 `<blocker-db-id>` 是阻擋者的數字**資料庫 id**（`gh api repos/<owner>/<repo>/issues/<n> --jq .id`，_不是_ `#number` 或 `node_id`）。GitHub 會回報 `issue_dependencies_summary.blocked_by`（只計算開放的阻擋者，也就是即時的關卡）。若相依關係不可用，就退回在子議題內文最上方放一行 `Blocked by: #<n>, #<n>`。當每個阻擋者都已關閉時，票券就是未被阻擋。
- **前沿查詢**：列出地圖的開放子議題（`gh issue list --state open`，範圍限於地圖的子議題／任務清單），排除有開放阻擋者（`issue_dependencies_summary.blocked_by > 0`，或 `Blocked by` 那行中有開放的議題）或有被指派者的；依地圖順序排第一的勝出。
- **領取**：`gh issue edit <n> --add-assignee @me`，這是工作階段的第一個寫入動作。
- **解決**：`gh issue comment <n> --body "<答案>"`，然後 `gh issue close <n>`，再把情境指標（要旨 + 連結）附加到地圖的「目前已做的決策」。
