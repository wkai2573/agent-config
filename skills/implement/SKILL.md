---
name: implement
description: "根據規格或一組票券，實作一項工作。"
disable-model-invocation: true
---

實作使用者在規格或票券中所描述的工作。

盡可能在事先約定的接縫上使用 /tdd。

定期執行型別檢查、定期執行單一測試檔案，最後再執行一次完整測試套件。

完成後，用 `model: sonnet` 的子代理執行 /code-review 審查這項工作，只收問題清單。

把你的工作 commit 到目前的分支。
