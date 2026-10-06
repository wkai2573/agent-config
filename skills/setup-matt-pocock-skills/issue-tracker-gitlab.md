# 議題追蹤系統：GitLab

這個倉庫的議題與規格以 GitLab 議題的形式存在。所有操作都使用 [`glab`](https://gitlab.com/gitlab-org/cli) CLI。

## 慣例

- **建立議題**：`glab issue create --title "..." --description "..."`。多行描述使用 heredoc。傳入 `--description -` 可開啟編輯器。
- **讀取議題**：`glab issue view <number> --comments`。使用 `-F json` 取得機器可讀的輸出。
- **列出議題**：`glab issue list -F json`，並搭配適當的 `--label` 篩選。
- **在議題上留言**：`glab issue note <number> --message "..."`。GitLab 把留言稱為「notes」。
- **套用／移除標籤**：`glab issue update <number> --label "..."` / `--unlabel "..."`。多個標籤可以用逗號分隔，或重複該旗標。
- **關閉**：`glab issue close <number>`。`glab issue close` 不接受關閉時的留言，所以先用 `glab issue note <number> --message "..."` 發佈說明，再關閉。
- **Merge request**：GitLab 把 PR 稱為「merge request」。使用 `glab mr create`、`glab mr view`、`glab mr note` 等，形式與 `gh pr ...` 相同，只是以 `mr` 取代 `pr`、以 `note`/`--message` 取代 `comment`/`--body`。

從 `git remote -v` 推斷倉庫；在 clone 內執行時，`glab` 會自動這樣做。

## 將 Merge Request 視為分流入口

**MR 作為需求入口：否。** _（如果這個倉庫把外部 merge request 視為功能需求，就設為 `yes`；`/triage` 會讀取這個旗標。）_

設為 `yes` 時，MR 會與議題走過相同的標籤與狀態，使用對應的 `glab mr` 指令：

- **讀取 MR**：`glab mr view <number> --comments`，以及用 `glab mr diff <number>` 取得 diff。
- **列出待分流的外部 MR**：`glab mr list -F json`，然後只保留作者不是專案成員／擁有者的 MR（貢獻者的 MR，而不是維護者進行中的工作）。
- **留言／標籤／關閉**：`glab mr note`、`glab mr update --label`/`--unlabel`、`glab mr close`。

與 GitHub 不同，GitLab 對議題與 MR 分別編號，所以一旦知道維護者指的是哪一個入口，`#42` 就沒有歧義。

## 當 skill 說「發佈到議題追蹤系統」

建立一個 GitLab 議題。

## 當 skill 說「取得相關票券」

執行 `glab issue view <number> --comments`。

## 尋路操作（Wayfinding operations）

由 `/wayfinder` 使用。**地圖**是單一議題，**子**議題就是票券。

- **地圖**：標上 `wayfinder:map` 標籤的單一議題，內文包含備註／目前已做的決策／迷霧。`glab issue create --label wayfinder:map`。（在有原生 epic 的 GitLab 方案上，也可以由 epic 來承載地圖；有標籤的議題則到處都能用。）
- **子票券**：描述最上方帶有 `Part of #<map>`、並有 `wayfinder:<type>` 標籤（`research`/`prototype`/`grilling`/`task`）的議題。一旦被領取，票券就指派給推動的開發者。
- **阻擋**：GitLab 的**原生阻擋連結**，是標準且在 UI 中可見的表示方式。以 `/blocked_by #<n>` 快速動作新增，並以留言發佈（`glab issue note <child> --message "/blocked_by #<blocker>"`）。原生阻擋連結是 Premium/Ultimate 的功能；在免費方案（或不可用時）則退回在描述最上方放一行 `Blocked by: #<n>, #<n>`。當每個阻擋者都已關閉時，票券就是未被阻擋。
- **前沿查詢**：`glab issue list -F json`，範圍限於地圖的子議題，排除有開放阻擋者的：指向開放議題的原生 `blocked_by` 連結（`glab api projects/:id/issues/:iid/links`）、`Blocked by` 那行中有開放的議題，或有被指派者的；依地圖順序排第一的勝出。
- **領取**：`glab issue update <n> --assignee @me`，這是工作階段的第一個寫入動作。
- **解決**：`glab issue note <n> --message "<答案>"`，然後 `glab issue close <n>`，再把情境指標（要旨 + 連結）附加到地圖的「目前已做的決策」。
