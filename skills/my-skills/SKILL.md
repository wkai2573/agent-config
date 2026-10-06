---
name: my-skills
description: 列出我自己放進去的 skills（指令與一句話用途）；加上名稱可看該 skill 的內容。
disable-model-invocation: true
argument-hint: "（選填）skill 名稱，直接顯示它的內容"
---

沒有傳入參數時，執行腳本，並把輸出原樣貼給使用者，不要加任何說明或建議。輸出中的 /指令 是 Markdown 連結，不要改動或拿掉連結：

```bash
python scripts/list_skills.py
```

有傳入 skill 名稱時，執行下面的指令，並把輸出放進一個 markdown 程式碼區塊貼給使用者，不要加說明：

```bash
python scripts/list_skills.py --show <名稱>
```

找不到 `python` 時改用 `python3`。腳本沒有輸出任何內容時，只回「沒有找到你自己的 skills。」，不要編造清單。
