---
paths:
  - "**/*.swift"
---

# Taskのクロージャーでのキャプチャルール

**`Task { }` のクロージャーに `[weak self]` を付けない。** `self` を素直に強参照する。

```swift
// ✅ 正しい
drainTask = Task {
    await self.drain()
}

// ❌ 誤り
drainTask = Task { [weak self] in
    await self?.drain()
}
```

## なぜ不要なのか

- **Taskのクロージャーは完了時に解放される。** `self.task = Task { ... }` のようにTaskを自分で
  保持していても、処理が終わればクロージャーごと解放されて`self`への参照は切れる。
  クロージャーを持ち続ける`escaping`なコールバックとは寿命の性質が違う
- **`[weak self]`を付けると、やるべき後片付けが黙って飛ぶ。** `self?.`や`guard let self else { return }`は
  「解放済みなら何もしない」という分岐であり、状態の反映やクリア処理を書いている場所では
  不具合そのものになる
- **戻り値の型が崩れる。** `Task { await self?.f() }` は `Task<()?, Never>` になるため、
  `Task<Void, Never>` として保持できずコンパイルエラーになる。`guard let self`で回避すると
  今度は本文のノイズが増える

## 終わらないTaskの扱い

`for await`で購読し続けるような、自然に完了しないTaskを`self`が保持する場合は参照が残り続ける。
これは`[weak self]`ではなく**`cancel()`で畳む導線を用意して解く**（`AccountStore.stopObserving()`が
`listenerTask?.cancel()`してから`nil`にしているのがこの形）。停止の責務を持たせずに弱参照で
逃げると、購読が残ったまま誰も止められない状態になる。
