# VRTを影響範囲に絞るためのUIモジュール分離 実装方針

> 関連Issue: [#513 CIのVRTを変更の影響範囲に絞る](https://github.com/stotic-dev/homete_iOS/issues/513)、[#514 HometeModelの切り出し](https://github.com/stotic-dev/homete_iOS/issues/514)、[#515 XxxFeatureUIへの分離](https://github.com/stotic-dev/homete_iOS/issues/515)
> ブランチ: Issueごとに切る（Step 1は `ci/513-affected-vrt`）
> ADR: [ADR-0063](../adr/0063-split-ui-modules-from-domain-for-affected-vrt.md)

## ステータス

- [x] 要件確定
- [ ] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

CI（Xcode Cloud）のVRTは、変更内容に関係なく全プレビューを流している。UIのモジュールをStore・UseCase・Clientから切り離し、
`HometeDomain`の変更がプレビューに届かない構成にしたうえで、CIのVRTをPRの影響範囲に入ったプレビューだけに絞る。

## 要件

### 機能要件

- PRのVRT（`VRT_light`）は、変更から推移的に影響を受けるVRTのモジュールのプレビューだけを流す
- 次の場合は全件を流す
  - `HometeModel`・`HometeUI`・`HometeResources`の変更
  - `Package.resolved`の変更
  - VRTの設定（`.prefire.yml`・テストプラン・`hometeVRT.xcodeproj`・`hometeSnapshotTests/Sources`・`hometeVRTHost`）の変更
  - リリースPR（`release/*` → `main`）
  - 差分の起点を決められなかったとき
- 対象が無ければテストを流さずに成功させる
- 記録したPNGのcommit・pushは今までどおり（流さなかった参照PNGはそのまま残る）

### 非機能要件 / 制約

- 移行はFeatureごとに段階的に進める。移行の途中でも判定が正しくなること
- スナップショットのファイル名はプレビュー名から決まる（`generateTestTemplate.stencil`）ので、Viewのファイルをモジュール間で
  動かしても参照PNGの名前は変わらない。移行で見た目の差分が出ないことをVRTで確かめる
- ユニットテストは`swift test`で回す方針のまま（ADR-0048）
- 1つのPRが500行を超えないように、Featureごとに分ける

## 設計方針

### 1. モジュール構成

```
HometeModel        … UIが使う値型のドメインモデル。依存なし
HometeDomain       … Store・UseCase・Clientのプロトコル・previewValue・UIが使わない値型。依存: HometeModel
HometeResources    … 変更なし
HometeUI           … 依存: HometeModel・HometeResources（HometeDomainを外す）
XxxFeatureUI       … UIのみのView（XxxView / XxxContent）・Featureの Model/ の値型・プレビュー
                     依存: HometeModel・HometeUI・HometeResources・（必要なら）YyyFeatureUI
XxxFeature         … XxxScreen / XxxComponent・Store連携。依存: XxxFeatureUI・HometeDomain・HometeUI・HometeResources
```

`Package.swift`には`feature(name:)`と同じように`featureUI(name:)`ヘルパーを足し、依存を固定する。
`XxxFeatureUI`が`HometeDomain`をimportするとコンパイルエラーになるので、ルール違反はビルドで検出される。

```swift
func featureUI(name: String, extraDeps: [Target.Dependency] = []) -> Target {
    .target(
        name: "\(name)UI",
        dependencies: ["HometeModel", "HometeUI", "HometeResources"] + extraDeps,
        path: "./Sources/Features/\(name)UI",
        resources: [localizableStrings()],
        plugins: [swiftLintPlugin()]
    )
}
```

### 2. HometeModelに移す型

UIが参照する型だけを移す。移す型は、`XxxFeatureUI`・`HometeUI`のビルドエラーを見ながら決める。

現時点の調査（`HometeDomain`のSwift 212ファイル）:

| 分類 | ファイル数 | 扱い |
|---|---|---|
| Client（`Dependencies/`） | 33 | `HometeDomain`に残す |
| Store | 24 | `HometeDomain`に残す |
| UseCase | 7 | `HometeDomain`に残す |
| ロジックを持つクラス（`HouseworkManager`・`CohabitantRegistrationMessageSender`） | 2 | `HometeDomain`に残す |
| 値型 | 約146 | UIが使うものだけ`HometeModel`へ |

値型のうち、`HometeDomain`に残す見込みのもの（UIが使わない）:

- `AnalyticsLog/`（19ファイル、2026-04以降で55回変更）
- `RemoteConfig/`・`AppIntent/`・`SignInWithApple/`・`NotificationCenter/`・`PendingRoute/`
- `Utilities/DebugHelper/`（プレビュー用のデータを含む場合は要確認）

注意が要るもの:

- `Cohabitant/CohabitantRegistration/`の状態機械の型（`CohabitantRegistrationState`など）は、`CohabitantRegistrationStateMachine`の
  `PeerID`（`CohabitantRegistrationPeerID`）を参照している。UIが状態を描画するなら、`PeerID`ごと`HometeModel`へ移す
- Storeのファイルに定義された値型（`WelcomeInvitation`・`InquiryListState`・`InquiryDetailState`など）は、UIが使うなら
  独立したファイルに出して`HometeModel`へ移す
- 表示用の文言を持つ値型（`CohabitantInvitation`・`FrequentHouseworkCategory`・`PresetFrequentHouseworkCategory`・`DayOfWeek`・
  `HouseworkRecurrence`・`MonthlyRecurrenceRule`・`DailyCompletionReminderRequest`・`SubscriptionPlan`・`PushNotificationContent`）は、
  使う文言を`HometeModel`のString Catalogへ移す。`LocalizedStringResource+Localized.swift`も`HometeModel`へ移す
- `Inquiry+Preview.swift`のようなプレビュー用のデータは、型と一緒に`HometeModel`へ移す

### 3. Storeに依存しているプレビューの書き直し

プレビューのあるファイル143件のうち、Store・UseCase・Clientの型を参照しているもの（同じファイルにScreenがある場合を含む）:

| モジュール | ファイル | 参照している型 |
|---|---|---|
| HometeUI | `Components/HouseworkMemo/HouseworkMemoEditScreen.swift` | `SubscriptionStore` |
| AuthFeature | `RegistrationAccount/RegistrationAccountView.swift` | `AccountStore`・`CohabitantStore`・`SubscriptionStore`・`AuthSubscriptionSyncUseCase` |
| | `Welcome/WelcomeView.swift` | `WelcomeInvitation` |
| | `Login/LoginView.swift` | `AccountAuthStore` |
| | `Onboarding/OnboardingFlowView.swift` | `AccountAuthStore`・`AccountStore`・`CohabitantStore`・`SubscriptionStore`・`AuthSubscriptionSyncUseCase` |
| | `Onboarding/PremiumIntroductionView.swift` | `SubscriptionStore` |
| ContributionFeature | `View/Summary/ContributionSummaryComponent.swift` | `PendingRouteStore` |
| HomeFeature | `HomeView/SubViews/NotRegisteredContent.swift` | `PasteboardInvitationStore` |
| | `HomeView/SubViews/PasteboardInvitationBanner.swift` | `PasteboardInvitationStore` |
| | `HomeView/SubViews/RegisteredContent/RegisteredContent.swift` | `CohabitantStore`・`EncouragementCommentStore`・`HouseworkListStore`・`SubscriptionStore` |
| HouseworkFeature | `IncompleteHouseworkListView/IncompleteHouseworkListView.swift` | `HouseworkListStore` |
| | `HouseworkDetailView/HouseworkDetailView.swift` | `CohabitantStore`・`HouseworkListStore`・`SubscriptionStore` |
| | `HouseworkBoardView/SubViews/HouseworkQuickActionMenuContent.swift` | `HouseworkListStore` |
| | `HouseworkThanks/HouseworkThanksView.swift` | `HouseworkListStore` |
| | `HouseworkAddHelper/HouseworkAddHelperSheet.swift` | `HouseworkListStore` |
| | `RegisterHouseworkView/RegisterHouseworkView.swift` | `FrequentHouseworkStore`・`HouseworkListStore`・`HouseworkTemplateListStore`・`ScreenTutorialStore`・`SubscriptionStore` |
| | `HouseworkComplete/HouseworkCompleteSheet.swift` | `HouseworkListStore` |
| HouseworkTemplateFeature | `Template/HouseworkTemplateView.swift` | `HouseworkTemplateListStore` |
| SettingFeature | `SettingView.swift` | `AccountAuthStore`・`AccountStore`・`InquiryListStore`・`SentInvitationStore`・`SubscriptionStore` |
| | `Inquiry/InquiryListScreen.swift` | `InquiryListStore`・`InquiryListState` |
| | `Inquiry/InquiryDetailScreen.swift` | `InquiryDetailStore`・`InquiryListStore`・`InquiryDetailState` |
| | `Inquiry/InquiryCreationScreen.swift` | `InquiryCreationStore` |
| | `SubscriptionManagement/SubscriptionManagementView.swift` | `SubscriptionStore` |

CohabitantRegistrationFeature・FrequentHouseworkFeatureには該当なし。

それぞれ、`ui-logic-view-separation`ルールに沿ってScreen（`XxxFeature`）とUIのみのView（`XxxFeatureUI`）に分け、
プレビューはUIのみのViewに値を渡して描画する。Storeの派生プロパティを表示に使っている箇所は、`HometeModel`の値型か
Screen側の算出プロパティに移す。

### 4. Feature間の依存

| 今の依存 | 分離後 |
|---|---|
| `HomeFeature` → `ContributionFeature`・`HouseworkFeature` | `HomeFeatureUI` → `ContributionFeatureUI`・`HouseworkFeatureUI`（Homeが埋め込むUIのみのView用）、`HomeFeature` → `ContributionFeature`・`HouseworkFeature` |
| `HouseworkFeature` → `FrequentHouseworkFeature` | 同様にUI同士・Feature同士で張る |
| `HometeAppIntents` → `HouseworkFeature`・`ContributionFeature` | 使っているのは`HouseworkBoardItem`・`TodayHouseworkSummary`・`ThanksPromptSummary`・`ContributionMonthlySummary`・`ContributionSnippetContent`。移した先（`XxxFeatureUI`か`HometeModel`）に依存を付け替える |

### 5. 影響範囲の判定とCI

判定は今の`affected-modules.py`の推移的な依存の計算をそのまま使い、VRTのモジュール（`testable_imports`）と交差させる。
未移行のFeatureは`HometeDomain`に依存したままなので、`HometeDomain`を変えると今までどおり対象に入る。移行済みかどうかの分岐は持たない。

- `affected-modules.py`に、CI用のクエリ（例: `vrt-tests --transitive`）を足す。ローカル用の`vrt-tests`（直接変えたモジュールだけ）は残す
- `Package.resolved`を全件扱いのパターンに足す
- `ci_post_xcodebuild.sh`の`VRT_light`で
  - `CI_PULL_REQUEST_TARGET_COMMIT`を起点に判定する（浅いcloneなら起点をfetchする。決められなければ全件）
  - `CI_PULL_REQUEST_SOURCE_BRANCH`が`release/`で始まれば全件
  - `build-for-testing`のあと、Prefireの生成コードと突き合わせて`-only-testing`を組み立て、`test-without-building`で流す
    （`run-affected-snapshots.sh`と同じ手順。共通化を検討する）

この判定は今の構成でも成り立つので、**モジュールの移行より先に入れる**。Featureだけ・Screenだけを変えたPRは、その時点で絞れる。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規モジュール | `LocalPackage/Sources/HometeModel/` | UIが使う値型 |
| 新規モジュール | `LocalPackage/Sources/Features/XxxFeatureUI/`（8つ） | UIのみのViewとプレビュー |
| 修正 | `LocalPackage/Package.swift` | `HometeModel`・`featureUI(name:)`の追加、依存の付け替え |
| 修正 | `.prefire.yml` | `testable_imports`を`HometeUI`と`XxxFeatureUI`に、`imports`に`HometeModel` |
| 修正 | `hometeVRT.xcodeproj` | テストターゲットのリンクを`XxxFeatureUI`に |
| 修正 | `scripts/affected-modules.py` | CI用のVRT判定、`VRT_MODULES`、全件扱いのパターン |
| 修正 | `ci_scripts/ci_post_xcodebuild.sh` | `VRT_light`の絞り込み |
| 修正 | `InfraPackage/Sources/AppRoot/` | 依存の付け替え（ビルドが通ることの確認） |
| 修正ドキュメント | `doc/multimodules_structure.md`・`CLAUDE.md`・`.claude/rules/ui-logic-view-separation.md`・`.claude/skills/swift-code-verification/SKILL.md` | モジュール構成とUIのみのViewの置き場所 |
| 修正ADR | `doc/adr/0048-verify-only-affected-modules.md` | CIのVRTも絞ることへの参照を追記 |

## タスク

### Phase 1: 設計確定

- [x] `HometeModel`に移すのは、UIが使う値型だけにする
- [x] UIのモジュールはFeatureごとに`XxxFeatureUI`を作る
- [x] 全件を流すのは、VRT関連の設定・`Package.resolved`・`HometeModel`/`HometeUI`/`HometeResources`の変更時と、リリースPR
- [ ] ADR-0063を承認する
- [x] Issueを起票する（#513 CIの絞り込み、#514 `HometeModel`の切り出し、#515 Featureごとの移行）

### Phase 2: 実装

**Step 1: CIのVRTを影響範囲に絞る（構成は変えない）**

- [x] `affected-modules.py`にCI用のVRT判定を足す（推移的な依存、`Package.resolved`を全件扱い）
- [x] `VRT_light`で起点の取得・リリースPRの判定・`-only-testing`の組み立てを行う
- [ ] Featureだけを変えたPR、`HometeDomain`を変えたPR、変更なしのPRで、対象が期待どおりになることを確かめる

**Step 2: `HometeModel`の切り出しと`HometeUI`の切り離し**

- [ ] `HometeModel`モジュールを作り、`HometeDomain`から依存する
- [ ] `HometeUI`が使う値型を`HometeModel`へ移し、`HometeUI`の依存から`HometeDomain`を外す
- [ ] `HouseworkMemoEditScreen`（`SubscriptionStore`に依存）をFeature側へ移すか、UIのみのViewに分ける
- [ ] 値型が使う文言を`HometeModel`のString Catalogへ移す（`make check-translations`）
- [ ] 値型のユニットテストを`HometeModelTests`へ移す

**Step 3: Featureごとの移行**（Storeへの依存が少ない順。Homeは依存先のContribution・Housework・FrequentHouseworkの後）

- [ ] CohabitantRegistrationFeature
- [ ] FrequentHouseworkFeature
- [ ] HouseworkTemplateFeature
- [ ] ContributionFeature
- [ ] AuthFeature
- [ ] SettingFeature
- [ ] HouseworkFeature
- [ ] HomeFeature

各Featureで行うこと:

- [ ] `XxxFeatureUI`を作り、UIのみのView・`Model/`の値型・プレビューを移す
- [ ] Storeを使っていたプレビューを、UIのみのViewに値を渡す形に書き直す
- [ ] UIが使う値型のうち未移行のものを`HometeModel`へ移す
- [ ] `.prefire.yml`の`testable_imports`、`hometeVRT.xcodeproj`のリンク、`affected-modules.py`の`VRT_MODULES`を更新する

**Step 4: ドキュメント**

- [ ] `doc/multimodules_structure.md`・`CLAUDE.md`を更新する
- [ ] `ui-logic-view-separation.md`に、UIのみのViewは`XxxFeatureUI`に置くことを追記する
- [ ] ADR-0048にCIのVRTも絞ることへの参照を追記し、ADR-0063を承認済にする

### Phase 3: 検証

- [ ] `make build-affected`・`make build-infra-package`でビルド通過
- [ ] `swift-code-verification`スキルに沿ってSwiftLint通過
- [ ] `make test-affected`通過
- [ ] VRTで、移行による見た目の差分が出ていないこと（参照PNGの差分が無いこと）
- [ ] CIのVRTが、PRの変更に応じて期待どおりの件数だけ流れること

### Phase 4: PR

- [ ] Step・Featureごとに PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- ADR: [ADR-0063](../adr/0063-split-ui-modules-from-domain-for-affected-vrt.md)、[ADR-0048](../adr/0048-verify-only-affected-modules.md)、[ADR-0052](../adr/0052-vrt-light-workflow-with-build-action.md)
- 既存実装（参考）:
  - `scripts/affected-modules.py`
  - `scripts/run-affected-snapshots.sh`
  - `ci_scripts/ci_post_xcodebuild.sh`
  - `.claude/rules/ui-logic-view-separation.md`
