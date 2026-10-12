---
name: find-skills
description: 幫使用者探索並安裝 agent skills。當使用者問「這個要怎麼做」、「幫我找做某件事的 skill」、「有沒有 skill 可以…」，或表達想擴充 agent 能力時使用。適用於使用者在找可能已有現成 skill 的功能。
---

# 尋找 Skills

這個 skill 幫你從開放的 agent skills 生態系中探索並安裝 skills。

來源：vercel-labs/skills 的 find-skills，已翻成繁體中文並依個人規範調整。

## 何時使用

當使用者：

- 問「怎麼做 X」，而 X 可能是已有現成 skill 的常見任務
- 說「幫我找做 X 的 skill」或「有沒有做 X 的 skill」
- 問「你能做 X 嗎」，而 X 是專門領域的能力
- 表達想擴充 agent 能力
- 想搜尋工具、範本或工作流程
- 提到希望在某個特定領域（設計、測試、部署等）有人幫忙

## 什麼是 Skills CLI

Skills CLI（`npx skills`）是開放 agent skills 生態系的套件管理器。Skills 是模組化的套件，用專門知識、工作流程與工具擴充 agent 的能力。

**常用指令：**

- `npx skills find [query] [--owner <owner>]`：互動式或用關鍵字搜尋 skills，可用 `--owner` 限定某個 GitHub 擁有者
- `npx skills add <package>`：從 GitHub 或其他來源安裝 skill
- `npx skills update`：更新所有已安裝的 skills

**瀏覽 skills：** https://skills.sh/

## 如何幫使用者找 Skills

### 步驟 1：了解需求

使用者請你幫忙時，先釐清：

1. 領域，例如前端框架、測試、設計、部署
2. 具體任務，例如寫測試、做動畫、審查 PR
3. 這是不是夠常見、很可能已有現成 skill 的任務

### 步驟 2：先看排行榜

跑 CLI 搜尋之前，先看 [skills.sh 排行榜](https://skills.sh/)，確認該領域是否已有知名的 skill。排行榜依總安裝數排序，最容易找到最多人用、最經得起考驗的選項。

### 步驟 3：搜尋 Skills

排行榜沒有涵蓋使用者的需求時，執行搜尋指令：

```bash
npx skills find [query] [--owner <owner>]
```

範例：

- 使用者問「怎麼讓我的 React 應用變快？」→ `npx skills find react performance`
- 使用者問「你能幫我審 PR 嗎？」→ `npx skills find pr review`
- 使用者說「我需要產生 changelog」→ `npx skills find changelog`

### 步驟 4：推薦前先驗證品質

**不要只憑搜尋結果就推薦 skill。** 一定要驗證：

1. **安裝數**：優先選 1K 以上的 skills，低於 100 要特別小心。
2. **來源信譽**：官方來源 `vercel-labs`、`anthropics`、`microsoft` 比不知名的作者可信。
3. **GitHub stars**：檢查來源 repo。stars 少於 100 的 repo，其 skill 要抱持懷疑。

### 步驟 5：向使用者呈現選項

找到相關的 skills 後，向使用者呈現：

1. skill 名稱與用途
2. 安裝數與來源
3. 使用者可以執行的安裝指令
4. skills.sh 上的詳細連結

回覆範例：

```
我找到一個可能有幫助的 skill！「react-best-practices」提供
Vercel 工程團隊整理的 React 與 Next.js 效能優化指引。
（185K 安裝）

安裝方式：
npx skills add vercel-labs/agent-skills@react-best-practices

詳細資訊：https://skills.sh/vercel-labs/agent-skills/react-best-practices
```

### 步驟 6：詢問是否安裝

使用者想繼續時，你可以代為安裝：

```bash
npx skills add <owner/repo@skill> -g -y
```

`-g` 表示安裝在全域（使用者層級），`-y` 表示略過確認提示。

## 常見 Skill 分類

搜尋時可以參考這些常見分類：

| 分類     | 查詢關鍵字                               |
| -------- | ---------------------------------------- |
| 網頁開發 | react, nextjs, typescript, css, tailwind |
| 測試     | testing, jest, playwright, e2e           |
| DevOps   | deploy, docker, kubernetes, ci-cd        |
| 文件     | docs, readme, changelog, api-docs        |
| 程式品質 | review, lint, refactor, best-practices   |
| 設計     | ui, ux, design-system, accessibility     |
| 生產力   | workflow, automation, git                |

## 有效搜尋的訣竅

1. **用具體關鍵字**：「react testing」比單純的「testing」好。
2. **換個說法**：「deploy」找不到時，試試「deployment」或「ci-cd」。
3. **看熱門來源**：許多 skills 來自 `vercel-labs/agent-skills` 或 `ComposioHQ/awesome-claude-skills`。

## 找不到 Skills 時

如果沒有相關的 skill：

1. 告知使用者沒有找到現成的 skill
2. 主動表示可以用你的通用能力直接幫忙
3. 建議使用者可以用 `npx skills init` 自己建立 skill

回覆範例：

```
我搜尋了與「xyz」相關的 skills，但沒有找到符合的結果。
我還是可以直接幫你處理這件事！要我開始嗎？

如果這是你常做的事，也可以自己建立 skill：
npx skills init my-xyz-skill
```
