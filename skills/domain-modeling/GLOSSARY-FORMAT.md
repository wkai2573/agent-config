# GLOSSARY.md 格式

## 結構

```md
# {情境名稱}

{一到兩句話，說明這個情境是什麼、為何存在。}

## 語言

**訂單（Order）**：
{一到兩句話的術語描述}
_避免使用_：採購、交易

**發票（Invoice）**：
交貨後寄給客戶的付款請求。
_避免使用_：帳單、付款請求

**客戶（Customer）**：
下訂單的個人或組織。
_避免使用_：客人、買家、帳號
```

## 規則

- **要有主見。** 同一個概念有多個詞時，挑最好的一個，其餘列在 `_避免使用_` 底下。
- **定義要精煉。** 最多一到兩句話。定義它「是」什麼，而不是它做什麼。
- **只收錄這個專案情境特有的術語。** 一般的程式設計概念（逾時、錯誤型別、工具模式）不屬於這裡，即使專案大量使用它們。加入術語之前先問：這是這個情境獨有的概念，還是一般的程式設計概念？只有前者才該收錄。
- **當自然形成群集時，用子標題分組。** 如果所有術語都屬於單一內聚的領域，用平面清單就可以。

## 單一情境 vs. 多情境倉庫

**單一情境（大多數倉庫）：** 在倉庫根目錄放一份 `GLOSSARY.md`。

**多個情境：** 在倉庫根目錄放一份 `GLOSSARY-MAP.md`，列出各個情境、它們放在哪裡，以及彼此如何關聯：

```md
# 詞彙表地圖

## 情境

- [Ordering](./src/ordering/GLOSSARY.md)：接收並追蹤客戶訂單
- [Billing](./src/billing/GLOSSARY.md)：產生發票並處理付款
- [Fulfillment](./src/fulfillment/GLOSSARY.md)：管理倉庫揀貨與出貨

## 關係

- **Ordering → Fulfillment**：Ordering 發出 `OrderPlaced` 事件；Fulfillment 消費它們以開始揀貨
- **Fulfillment → Billing**：Fulfillment 發出 `ShipmentDispatched` 事件；Billing 消費它們以產生發票
- **Ordering ↔ Billing**：共用 `CustomerId` 與 `Money` 的型別
```

這個 skill 會推斷適用哪種結構：

- 如果存在 `GLOSSARY-MAP.md`，就讀它以找出各個情境
- 如果只有根目錄的 `GLOSSARY.md`，就是單一情境
- 如果兩者都沒有，就在第一個術語確定時，延遲建立根目錄的 `GLOSSARY.md`

當存在多個情境時，推斷目前的主題與哪一個有關。如果不清楚，就詢問。
