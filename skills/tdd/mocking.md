# 何時要 Mock

只在**系統邊界**進行 mock：

- 外部 API（支付、電子郵件等）
- 資料庫（有時候：優先使用測試資料庫）
- 時間／隨機性
- 檔案系統（有時候）

不要 mock：

- 你自己的類別／模組
- 內部協作者
- 任何你能控制的東西

## 為可 mock 性而設計

在系統邊界上，設計容易 mock 的介面：

**1. 使用相依性注入**

把外部相依性傳進來，而不是在內部建立：

```typescript
// 容易 mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// 難以 mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. 偏好 SDK 風格的介面，而不是通用的 fetcher**

為每個外部操作建立特定的函式，而不是一個帶有條件邏輯的通用函式：

```typescript
// 好：每個函式都能獨立 mock
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// 壞：mock 時需要在 mock 內部寫條件邏輯
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

SDK 方式意味著：
- 每個 mock 回傳一種特定的形狀
- 測試設置中沒有條件邏輯
- 更容易看出測試涵蓋了哪些端點
- 每個端點都有型別安全
