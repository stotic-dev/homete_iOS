---
paths:
  - "**/*.swift"
---

# Prefireプレビュー実装のルール

`#Preview` は Prefire によって `hometeSnapshotTests/PreviewTests.generated.swift` へ**中身がそのまま展開**され、対象モジュールを `@testable import` した上でビルドされる（生成の設定は `.prefire.yml`）。

そのため `#Preview` は、実装ファイルの中に書かれていても**別モジュール・別ファイルからコンパイルされる**前提で書く必要がある。ここを外すと、ローカルの `make test-packages` は通るのに Xcode Cloud の `VRT` ワークフローだけがビルドエラーで落ちる（LocalPackage単体のビルドでは生成コードがビルド対象に入らないため、手元では再現しない）。

## 必須事項

### 1. `#Preview` から参照するシンボルは internal 以上にする

`private` / `fileprivate` なシンボルを `#Preview` の中で参照しない。生成先ファイルからは見えず、次のエラーになる。

```
'setupStorageEnvironmentForPreview' is inaccessible due to 'fileprivate' protection level
```

とくに踏みやすいのが、プレビュー専用のヘルパーを実装ファイルの末尾に `private extension View` で置くパターン。**プレビュー用ヘルパーは `LocalPackage/Sources/HometeDomain/Utilities/DebugHelper/Preview/PreviewEnvironment.swift` に `public` で置く**（`setupEnvironmentForPreview()` / `setupStorageEnvironmentForPreview(now:storagePolicy:)` と同じ場所）。1ファイルでしか使わないヘルパーでも、そこに置けば再発しない。

同様に `private struct XxxPreviewWrapper: View` のようなプレビュー用のラッパー型も `private` にしない。

### 2. `Prefire` の import は `#if canImport(Prefire)` で囲む

`LocalPackage/Package.swift` で `Prefire` プロダクトは `condition: .when(platforms: [.iOS])` としてiOS限定でリンクされている。`swift test --package-path LocalPackage`（`make test-packages`）が実行するホストmacOS向けビルドには `Prefire` モジュールが存在しないため、無条件の `import Prefire` は `error: no such module 'Prefire'` で失敗する。

```swift
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif
```

`.snapshot()` などの呼び出し側（`#Preview` 内）も同様に囲む。

### 3. 新しいモジュールに `#Preview` を置いたら `.prefire.yml` に登録する

`.prefire.yml` の `testable_imports`（Feature系モジュール）または `imports`（`HometeDomain` など）に列挙されていないモジュールのViewは、生成されたテストから参照できない。

### 4. `contextMenu` / `alert` / `sheet` など提示系モディファイアはPreviewでラップしない

VRT（Prefireのスナップショット撮影）は画面を静的にレンダリングするだけなので、`.contextMenu { }` の中身、`.alert(...)`、`.sheet(...)` のように**ユーザー操作（長押し・ボタンタップなど）をトリガーに表示される内容はスナップショットに映らない**。これらでラップした`#Preview`を書いても、実際にはラップの外側（何もトリガーしていない状態の画面）しか撮影されず、中身の見た目はVRTで一切検証できない。

対応方針: 提示される中身が独立した`View`として切り出せるなら、**その中身のView自体を`#Preview`の対象にする**（親Viewの`.contextMenu { }`等でラップしない）。`HouseworkQuickActionMenuContent`（`.contextMenu { }`の中身として使うView）がこの形の実例で、Previewは`HouseworkQuickActionMenuContent`をトップレベルにそのまま描画し、`.contextMenu`では包まない。

```swift
// ✅ 中身のViewを直接Previewする（VRTで見た目を検証できる）
#Preview("HouseworkQuickActionMenuContent_未完了", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(item: .makeForPreview(state: .incomplete), onError: { _ in })
        .environment(HouseworkListStore())
}

// ❌ contextMenuでラップしても中身はVRTに映らない
#Preview {
    Text("家事セル")
        .contextMenu {
            HouseworkQuickActionMenuContent(item: .makeForPreview(state: .incomplete), onError: { _ in })
        }
}
```

呼び出し元Viewの`.contextMenu { HouseworkQuickActionMenuContent(...) }`自体は実装として必要なので残してよい。避けるべきなのは「Preview側でも同じラップ構造を再現すること」。

### 5. プレビューの描画を実行日時に依存させない

`\.now` の既定値は実行時の現在日時のため、固定日付を前提にしたプレビューは**時間が経つだけで表示が変わり**、意図しないVRT差分になる。保存期間やバッジ表示など日時で分岐するViewのプレビューでは `setupStorageEnvironmentForPreview(now:storagePolicy:)` などで現在日時とプランを固定する。

### 6. UI表示に影響する修飾子はScreen層に逃がさず、`#Preview`を持つView層に書く

`XxxScreen`（`AppDependencies`・Store・Routerなど環境依存の注入や`NavigationStack`の所有が責務のfeature root）と `XxxView`（`#Preview`を持つ純粋なUI層）が分かれている画面では、レイアウトや新規UIコンポーネントの適用（`.safeAreaInset`、バナーの追加など）は必ずView層の`body`に書く。Screen層は環境から取り出した値やアクションのクロージャをパラメータとして渡すだけにする。

「参照スナップショットの差分を避けたい」という理由でUI変更をScreen層側の修飾子として追加するのは禁止。Screen層は`#Preview`から生成されるVRTの対象外なので、そこにUI変更を置くと見た目が変わったこと自体がVRTで検知できなくなる。VRTで差分が出るのは意図した変更を正しく検知できているということなので、差分を避けるのではなく更新される参照スナップショットをレビューする。

実例: `BottomAdBanner`（広告バナー + Paywall導線）の適用を`ContributionAnalyticsScreen`/`HouseworkTemplateScreen`側の修飾子として実装したところ、VRTの対象である`ContributionAnalyticsView`/`HouseworkTemplateView`の`#Preview`に反映されず、広告バナー表示という見た目の変更をVRTで検知できなかった（PR #217）。`isPremium: Bool` と `onTapPromotionLink: () -> Void` をView層のパラメータとして追加し、`.bottomAdBanner(...)` をView層の`body`に移すことで解決した。

### 7. 表示バリエーションは、そのバリエーションを持つコンポーネント自身の`#Preview`で網羅する

あるコンポーネントの見た目が入力によって変わる場合、その組み合わせは**コンポーネント自身の
`#Preview`**で並べる。親Viewの`#Preview`を増やしてバリエーションを撮る方針は取らない。

- 親のPreviewは組み合わせの数だけ画面全体を撮ることになり、参照スナップショットが重くなる上、
  差分が出たときに「どのコンポーネントのどの状態が変わったのか」が読み取りにくい
- 親のPreviewは、コンポーネントを実際に配置したときのレイアウト（余白・重なり・スクロール領域と
  の関係）を1〜2枚だけ確認する用途に留める

コンポーネントが`@Environment`からStoreや`loginContext`を引いて表示内容を導出していると、
Previewで状態を作り分けられずこの方針が成立しない。表示内容の判断は呼び出し側に持たせ、
コンポーネントは引数で受け取る形にすること（[presentation-logic-placement.md](presentation-logic-placement.md)）。

```swift
// ✅ コンポーネント側でバリエーションを並べる
#Preview("HouseworkBulkActionBar_未完了_未選択", traits: .sizeThatFitsLayout) {
    HouseworkBulkActionBar(actions: [.requestReview, .remove], isEnabled: false, onTap: { _ in })
}

#Preview("HouseworkBulkActionBar_承認待ち_確認者", traits: .sizeThatFitsLayout) {
    HouseworkBulkActionBar(actions: [.approve, .reject], isEnabled: true, onTap: { _ in })
}
```

条件付きで表示されるコンポーネント（`.safeAreaInset`や`if`の中身）は、親のPreviewの初期状態
次第でそもそも描画されず、**VRTで1枚も撮れていない状態になりやすい**。Previewを追加したら、
その条件が満たされた状態のPreviewが存在するかを確認すること。

## 検証

上記1〜3は静的に検出できる。Swiftを変更したら実行すること（Stopフックと `local_package_test` ワークフローでも自動実行される）。

```bash
make check-previews
```

VRT自体はローカルで実行しない（`.claude/rules/swift-code-verification.md` 参照）。参照スナップショットの更新は Xcode Cloud の `VRT` ワークフローに任せる。

## 参考実装

- `LocalPackage/Sources/HometeDomain/Utilities/DebugHelper/Preview/PreviewEnvironment.swift`
- `LocalPackage/Sources/HometeUI/Components/Indicator/LoadingIndicator.swift`
- `LocalPackage/Sources/Features/ContributionFeature/View/Analytics/ContributionAnalyticsView.swift`（UI変更をScreen層に逃がさずView層に含めた例）
