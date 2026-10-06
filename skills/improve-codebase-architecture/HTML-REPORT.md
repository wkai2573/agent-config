# HTML 報告格式

架構審查會渲染成作業系統暫存目錄中的單一自足 HTML 檔案。Tailwind 與 Mermaid 都來自 CDN。Mermaid 能可靠地處理圖形狀的圖表；手工打造的 div 與內嵌 SVG 則處理更具編輯風格的視覺化（質量圖、剖面圖）。兩者混合使用：不要凡事都依賴 Mermaid，否則會開始顯得千篇一律。

## 骨架

```html
<!doctype html>
<html lang="zh-Hant">
  <head>
    <meta charset="utf-8" />
    <title>{{repo 名稱}} 的架構審查</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      /* 為 Tailwind 無法乾淨處理的東西準備的小型自訂層：
         虛線接縫、手繪感的箭頭等。 */
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## 標頭

倉庫名稱、日期，以及精簡的圖例：實線方塊 = 模組、虛線 = 接縫、紅色箭頭 = 洩漏、粗黑框方塊 = 深模組。不要寫引言段落。直接進入候選項。

## 候選項卡片

圖表承擔主要份量。文字稀疏、平實，並毫不拘謹地使用詞彙表中的術語（來自 `/codebase-design` skill）。

每個候選項是一個 `<article>`：

- **標題**：簡短，點出這次深化（例如「收合 Order 接收管線」）。
- **徽章列**：建議強度（`強烈建議（Strong）` = emerald、`值得探索（Worth exploring）` = amber、`推測性（Speculative）` = slate），外加相依性類別的標籤（`in-process`、`local-substitutable`、`ports & adapters`、`mock`）。
- **檔案**：等寬字體清單，`font-mono text-sm`。
- **前／後圖表**：核心主角。兩欄並排。見下方的模式。
- **問題**：一句話。什麼地方痛。
- **解決方案**：一句話。什麼會改變。
- **成效**：項目符號，每項 ≤ 12 字。例如「測試只打一個介面」、「定價邏輯不再洩漏」、「刪除 4 個淺層包裝」。
- **ADR 提示框**（若適用）：琥珀色底框裡的一行。

不要寫成大段解釋。如果圖表需要一整段文字才看得懂，就重畫圖表。

## 圖表模式

挑選符合該候選項的模式。混合使用。不要讓每張圖表都長得一樣。多樣性就是重點的一部分。

### Mermaid 圖（相依性／呼叫流程的主力）

當重點是「X 呼叫 Y 呼叫 Z，看看這一團亂」時，使用 Mermaid 的 `flowchart` 或 `graph`。把它包在以 Tailwind 設定樣式的卡片裡，讓它不會顯得突兀。用 classDef 設定樣式，把洩漏的邊畫成紅色、深模組畫成深色。序列圖很適合表達「之前：6 次往返；之後：1 次」。

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[OrderHandler] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### 手工打造的方框加箭頭（當 Mermaid 的版面跟你作對時）

模組用帶邊框與標籤的 `<div>`。箭頭用內嵌的 SVG `<line>` 或 `<path>` 元素，絕對定位在相對定位的容器上。當你希望「之後」的圖表感覺像是一個粗邊框、內部灰化的深模組時就用這個，因為 Mermaid 無法以正確的份量呈現。

### 剖面圖（適合分層的淺）

堆疊水平色帶（`h-12 border-l-4`）來顯示一次呼叫穿過的各層。之前：6 個什麼也不做的薄層。之後：1 個標有整合後職責的厚色帶。

### 質量圖（適合「介面與實作一樣寬」）

每個模組兩個矩形：一個代表介面表面積，一個代表實作。之前：介面矩形幾乎和實作矩形一樣高（淺）。之後：介面矩形很矮，實作矩形很高（深）。

### 呼叫圖塌縮

之前：渲染成巢狀方框的函式呼叫樹。之後：同一棵樹塌縮成一個方框，現在變成內部的呼叫以淡化的方式顯示在裡面。

## 樣式指引

- 偏向編輯風格，而不是企業儀表板。寬鬆的留白。標題可選用襯線體（`font-serif` 搭配 stone/slate 效果很好）。
- 色彩節制使用：一個強調色（emerald 或 indigo），外加洩漏用的紅色、警告用的琥珀色。
- 圖表高度維持約 320px，讓前／後並排時不必捲動也能舒適呈現。
- 圖表內的模組標籤使用 `text-xs uppercase tracking-wider`，讓它們讀起來像示意圖，而不是 UI。
- 唯一的腳本是 Tailwind CDN 與 Mermaid ESM 匯入。報告除此之外都是靜態的：沒有應用程式碼，除了 Mermaid 自己的渲染之外沒有互動。

## 最優先建議章節

一張較大的卡片。候選項名稱、一句話說明原因、指向其卡片的錨點連結。就這樣。

## 語氣

白話、簡潔，但架構上的名詞與動詞直接取自 `/codebase-design` skill。簡潔不是漂移的藉口。

**請精確使用：** 模組（module）、介面（interface）、實作（implementation）、深度（depth）、深（deep）、淺（shallow）、接縫（seam）、轉接器（adapter）、槓桿（leverage）、局部性（locality）。

**絕不替換成：** component、service、unit（指 module 時）· API、signature（指 interface 時）· boundary（指 seam 時）· layer、wrapper（想說 module 時）。

**符合風格的措辭：**

- 「Order 接收模組是淺的：介面幾乎等同於實作。」
- 「定價跨越接縫洩漏。」
- 「深化：一個介面，一個測試的地方。」
- 「兩個轉接器證成這道接縫：正式環境用 HTTP，測試用記憶體內。」

**成效項目符號**用詞彙表的術語說出收益：*「局部性：bug 集中在一個模組」*、*「槓桿：一個介面，N 個呼叫點」*、*「介面縮小；實作吸收了包裝層」*。不要寫*「更容易維護」*或*「更乾淨的程式碼」*，因為這些詞不在詞彙表裡，也不配佔有一席之地。

不要含糊、不要清喉嚨式的開場、不要「值得注意的是……」。如果一個句子可以變成項目符號，就把它變成項目符號。如果一個項目符號可以砍掉，就砍掉。如果某個術語不在 `/codebase-design` 詞彙表中，先找詞彙表裡有的詞，再去發明新詞。
