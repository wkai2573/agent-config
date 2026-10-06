# 好測試與壞測試

## 好測試

**整合風格**：透過真正的介面測試，而不是對內部零件的 mock。

```typescript
// 好：測試可觀察的行為
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

特徵：

- 測試使用者／呼叫者在乎的行為
- 只使用公開 API
- 能撐過內部重構
- 描述「什麼」，而不是「怎麼做」
- 每個測試一個邏輯斷言

## 壞測試

**實作細節測試**：與內部結構耦合。

```typescript
// 壞：測試實作細節
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

警訊：

- mock 內部協作者
- 測試私有方法
- 斷言呼叫次數／順序
- 重構而行為沒變時，測試壞了
- 測試名稱描述的是「怎麼做」而不是「什麼」
- 透過外部手段而不是介面來驗證

```typescript
// 壞：繞過介面來驗證
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// 好：透過介面驗證
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

**套套邏輯式測試**：預期值只是重述實作，所以測試依構造而通過。

```typescript
// 壞：預期值是用與程式碼相同的方式重新計算出來的
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// 好：預期值是獨立、已知的字面值
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```
