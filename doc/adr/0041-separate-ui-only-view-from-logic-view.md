## タイトル: 画面をUIのみのViewとロジックを持つViewに分け、チュートリアルでもUIを使い回す

* **ステータス: 承認済**
* 意思決定者: stotic-dev, Claude Code
* 日付: 2026-10-04
* 関連: #391、[presentation-logic-placement.md](../../.claude/rules/presentation-logic-placement.md)、[ui-logic-view-separation.md](../../.claude/rules/ui-logic-view-separation.md)

## 文脈、背景や問題点の説明

グループ登録の直後に、ダッシュボードと家事ボードの使い方を案内するチュートリアルを出す（#391）。
説明の対象のUIをハイライトするには実際の画面を見せる必要があるが、登録直後は家事が1件もなく、
ありがとうを伝えるハートや割合グラフがそもそも表示されない。

一方、家事ボード（`HouseworkBoardView`）やダッシュボードの各セクションは、`Environment`からStoreや
`loginContext`を取り、シートや画面遷移も自分で持っていたため、サンプルの値を渡して表示し直すことができなかった。
チュートリアル用に見た目を真似た画面を別に作ると、本番のUIを変えるたびにチュートリアル側も直す必要がある。

## 決定事項

* 画面は`XxxScreen`（ロジック）と`XxxView`（UIのみ）、画面の一部は`XxxComponent`（ロジック）と`XxxContent`（UIのみ）に分ける
* UIのみのViewは値・`Binding`・クロージャだけを受け取る。Storeを使う中身（長押しメニューなど）は`@ViewBuilder`の引数で差し込む
* チュートリアルは、UIのみのViewにサンプルの家事を渡した画面（`HouseworkBoardTutorialView`・`DashboardTutorialView`）を本番の画面に重ねて表示する
* ハイライトは`HometeUI`の`tutorialSpotlight`で行う。対象のUIには`.tutorialSpotlightTarget(_:)`を付け、スポットライトを出している間だけ画面全体の座標で位置を伝える。ナビゲーションバーや`TabView`の中のUIも同じ仕組みで切り抜ける
* 今後のUI実装もこの分け方で統一する（`.claude/rules/ui-logic-view-separation.md`）

## 考慮した選択肢

* **本番の画面にサンプルのStoreを渡す** — Viewの変更は少ないが、Storeの購読や`.task`の処理が動き、サンプルが本物のデータで上書きされる。Analyticsも送られてしまう
* **チュートリアル用に見た目を真似た画面を作る** — 本番のUIと二重管理になり、UIを変えるたびにチュートリアルがずれる
* **画面の上に説明のカードだけを出す（以前の実装）** — 実装は小さいが、どのUIの話かが伝わりにくい
* **UIのみのViewとロジックを持つViewに分け、UIのみのViewにサンプルを渡す（採用）**

## 決定結果

### 決定にあたり考慮したメリット

* 家事ボードやダッシュボードのUIを変えると、チュートリアルにもそのまま反映される
* UIのみのViewは引数だけで状態を作れるため、Previewで表示のバリエーションをVRTに載せやすい
* 家事の操作・シート・画面遷移がロジック側の1箇所に集まる

### 決定にあたり考慮したデメリット

* 引数とクロージャが増え、呼び出し側のコードが長くなる
* 既存の画面は分け方が揃っていない（`RegisteredContent`、`HouseworkQuickActionMenuContent`など）。触る機会に順次分ける
* チュートリアルの間はUIのみのViewが本番の画面に重なるため、本番の画面のUIが同じ識別子で位置を伝えないよう、`excludedFromTutorialSpotlight()`で外す必要がある

## 参考

* `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/HouseworkBoardScreen.swift`
* `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/HouseworkBoardView.swift`
* `LocalPackage/Sources/HometeUI/Components/Tutorial/TutorialSpotlight.swift`
* `LocalPackage/Sources/AppRoot/AppTabView.swift`
