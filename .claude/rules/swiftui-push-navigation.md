# SwiftUI Push遷移の実装ルール

**対象範囲**: このルールはSwiftの実装（`*.swift`、特に`LocalPackage/Sources/Features/`配下のView実装）でのみ参照する。TypeScript（`firebase/functions/`）など他言語の実装時は無関係なので読みに行かない。

Swiftファイルで`NavigationStack`を用いたpush遷移を実装する際は、既存コードベースで確立されているパターンに従うこと。

## 対象となる画面（NavigationStackを直接所有するfeature root）

`NavigationStack`を持ち、複数の遷移先を持つ画面（例: `SettingViewScreen`、`HouseworkBoardView`）は、以下の「Route enum + AppNavigationPath」パターンで実装する。

### 1. Route enumを定義する

feature配下に `XxxRoute.swift` を作成し、遷移先を列挙する `enum XxxRoute: Hashable` を定義する。遷移先が値を必要とする場合は連想値として持たせる。

```swift
enum SettingRoute: Hashable {

    /// ライセンス一覧画面
    case licenseList
    /// ライセンス詳細画面
    case licenseDetail(OSSLicense)

}
```

同じファイルに、`EnvironmentValues`への`@Entry`拡張として`AppNavigationPath<XxxRoute>`を生やす（`HometeUI`の`AppNavigationPath`を使う）。

```swift
extension EnvironmentValues {

    @Entry var settingNavigationPath = AppNavigationPath<SettingRoute>()

}
```

### 2. NavigationStackを所有するViewで一元管理する

`NavigationStack`を持つViewに`@State var navigationPath = AppNavigationPath<XxxRoute>()`を持たせ、`NavigationStack(path: $navigationPath.path)`にバインドする。`.navigationDestination(for: XxxRoute.self)`は**このView1箇所だけ**に定義し、配下には`.environment(\.xxxNavigationPath, navigationPath)`で伝播する。

```swift
public struct SettingViewScreen: View {

    @State var navigationPath = AppNavigationPath<SettingRoute>()

    public var body: some View {
        NavigationStack(path: $navigationPath.path) {
            SettingView()
                .navigationDestination(for: SettingRoute.self) { route in
                    navigationHandler(route)
                }
                .environment(\.settingNavigationPath, navigationPath)
        }
    }

}

private extension SettingViewScreen {

    @ViewBuilder
    func navigationHandler(_ route: SettingRoute) -> some View {
        switch route {
        case .licenseList:
            LicenseListView()

        case let .licenseDetail(license):
            LicenseDetailView(license: license)
        }
    }

}
```

### 3. 子Viewからの遷移トリガーは `navigationPath.push(...)`

子Viewは`@Environment(\.xxxNavigationPath) var navigationPath`でパスを受け取り、`Button`のaction内で`navigationPath.push(.case)`を呼ぶ。`NavigationLink(value:)`は使わない（値駆動の`NavigationLink`と`AppNavigationPath`によるpush管理が二重化するため）。

```swift
Button {
    navigationPath.push(.licenseDetail(license))
} label: {
    // 行の見た目
}
```

## 禁止事項

- `@State var isShowXxx: Bool` + `.navigationDestination(isPresented:)` を、複数遷移先を持つfeature rootのpush遷移に使わない（このパターンは末端コンポーネント内の単発遷移専用）
- ドメイン値型を直接`.navigationDestination(for: SomeDomainType.self)`のroute代わりに使わない。必ずfeature専用のRoute enumを経由する
- 1つのNavigationStack配下に`.navigationDestination(for:)`を複数箇所に分散させない（Route enumとハンドラをNavigationStack所有Viewに集約する）

## 例外（末端コンポーネントの単発push遷移）

`NavigationStack`を所有しない、埋め込みコンポーネント内で完結する単発遷移（他に遷移先を持たない）に限り、`@State var isShowXxx = false` + `.navigationDestination(isPresented:)` や `.navigationDestination(item:)` を使ってよい（例: `ContributionSummaryComponent`、`HouseworkTemplateView`）。ただし、遷移先が増える見込みがある場合は最初からRoute enumパターンを採用すること。

## 参照実装

- `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/HouseworkBoardRoute.swift`
- `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/HouseworkBoardView.swift`
- `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/HouseworkBoardListContent.swift`
- `LocalPackage/Sources/Features/SettingFeature/SettingRoute.swift`
- `LocalPackage/Sources/Features/SettingFeature/SettingView.swift`
- `LocalPackage/Sources/HometeUI/ViewUtilities/Navigation/AppNavigationPath.swift`
