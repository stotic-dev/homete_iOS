# Prefireインポートのルール

`LocalPackage/Package.swift` で `Prefire` プロダクトは `condition: .when(platforms: [.iOS])` でiOSプラットフォーム限定でリンクされている。そのため、`swift test --package-path LocalPackage`（`make test-packages`）が実行するホストmacOS向けビルドでは `Prefire` モジュールが存在せず、無条件の `import Prefire` は `error: no such module 'Prefire'` でビルド失敗する。

## 必須事項

`LocalPackage/Sources/` 配下のSwiftファイルで `Prefire` をimportする場合、必ず `#if canImport(Prefire)` で囲むこと。

```swift
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif
```

`.snapshot()` などPrefireのAPI呼び出し側（`#Preview` 内など）も同様に `#if canImport(Prefire) ... #endif` で囲む。

## 参考実装

- `LocalPackage/Sources/HometeUI/Components/Indicator/LoadingIndicator.swift`
- `LocalPackage/Sources/Features/HouseworkFeature/RegisterHouseworkView/RegisterHouseworkView.swift`
- `LocalPackage/Sources/Features/ContributionFeature/View/Summary/ContributionSummaryComponent.swift`
