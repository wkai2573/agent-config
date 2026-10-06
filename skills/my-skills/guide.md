我的開發流程
/grill-with-docs → /to-spec → /to-tickets → /implement
（新專案第一次：先 /setup-matt-pocock-skills）

想做什麼 → 用什麼
- 想法還模糊，想被盤問    → /grill-with-docs（在專案裡）／/grill-me（沒有專案）
- 把討論變成規格          → /to-spec（只寫要解決什麼問題，不放程式碼）
- 拆成小任務              → /to-tickets（照使用者功能拆，互不相干的可同時發給多個 AI）
- 開始寫程式              → /implement（自動走 TDD，寫完自動做 code review）
- 想用測試先行做一個功能  → /tdd（先寫測試、紅燈，再寫程式到綠燈）
- 專有名詞講不清楚        → /domain-modeling
- 設計模組介面            → /codebase-design
- 整理程式碼架構（保養）  → /improve-codebase-architecture（每隔幾天跑一次，產生 HTML 報告，挑最急的一項請 AI 重構）

提醒自己
- 盤問 → 規格 → 拆票在同一個對話裡做完，中途不要 /clear
- 每張票券 /implement 之間才 /clear
- 已經有規格（自己寫、別人給、別的 AI 產的）：跳過前面，直接 /to-tickets
- 小功能不用拆票，盤問完直接 /implement
- 不必走完整條，哪一步不需要就略過
- 想看某個 skill 怎麼寫的：/my-skills 名稱（例如 /my-skills grill-me）

接手既有專案時（照順序做一次）

1. /setup-matt-pocock-skills
   用途：替專案做一次性設定，讓其他 skills 知道任務存哪、文件放哪
   為什麼：沒設定的話，/to-spec、/to-tickets 會叫你先跑它
   怎麼用：在專案資料夾輸入指令，照它建議的答案回答即可

2. /improve-codebase-architecture
   用途：幫專案做一次架構健檢，找出結構混亂、難維護的地方
   為什麼：接手舊專案時，先知道哪裡最痛，再決定改哪裡
   怎麼用：輸入指令，看它產生的 HTML 報告，挑最急的一項和它討論怎麼改（只診斷，不會自己改程式）

3. /grill-with-docs
   用途：開工前讓 AI 盤問你的需求，同時把專有名詞和決策記成文件
   為什麼：舊專案最容易忘記「當初為什麼這樣做」，邊做邊補最不費力
   怎麼用：輸入指令並描述下一個要做的功能，一題一題回答

4. 之後的新功能：/grill-with-docs → /to-spec → /to-tickets → /implement

小提醒
- 要 /implement 之前，先切到功能分支
- 想補測試時用 /tdd，它會先跟你約定要測哪些地方，不用一次補全部
- 不要一次大改，舊程式碼碰到時才整理
- .scratch/ 放的是任務檔，不想進版本控制就加進 .gitignore
- 之後可以再裝：/diagnosing-bugs（難搞的 bug）、/triage（議題太多）、/retro（AI 搞砸後檢討環境）
