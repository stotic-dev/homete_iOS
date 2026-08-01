## タイトル: 家事テンプレートを仮想ビュー方式で表示する（書き込みを伴う「適用」を廃止する）

* **承認済**
* stotic-dev
* 日付: 2026-05-14
* 関連 Issue: #67、#139

## 文脈、背景や問題点の説明

家事週間テンプレート機能（#67）の当初設計では、「テンプレートを適用する」とは、テンプレートに定義された家事を `Houseworks` コレクションに `incomplete` 状態のドキュメントとして書き込み、画面上は既存の Houseworks リスナーで自然に表示する方式を想定していた。

しかし以下の問題が判明した。

* テンプレートはユーザーの生活スタイルの変化に応じて頻繁に編集される性質を持つ
* 1テンプレート×7曜日に複数アイテムが定義されると、対象期間（例: 1週間）の生成だけでも数十件、これを毎回 Firestore に書き込むことになる
* 編集のたび、または定期実行（自動適用）のたびに大量の delete + insert が発生し、Firestore の書き込み料金とクォータの両面で現実的でない
* `Cohabitant.appliedTemplates` でスキップ判定を行うなど整合性管理のための追加コストも積み上がる

**書き込みを伴う「適用」操作なしに、テンプレートと実際の家事を整合させて表示する方法はないか？**

## 決定事項

* **テンプレート適用時に `Houseworks` コレクションへドキュメントを書き込まない**
* テンプレートの家事は `HouseworkTemplates/{templateId}/Days/{dayOfWeek}` に保持し、`HouseworkBoardView` 表示時にテンプレート定義と `Houseworks` をマージして「仮想 incomplete」として表示する
* ユーザーが仮想 incomplete を `pendingApproval` 以降の状態に遷移させた瞬間、初めて `Houseworks` コレクションにドキュメントを Lazy 作成する
* テンプレートの各家事アイテムに安定 ID `id` と `updatedAt` を持たせる
* `HouseworkItem` に `templateHouseworkItemId: String?` を追加し、テンプレート由来の Housework であればテンプレートアイテムへの参照を持つ
* **表示マージルール**（`HouseworkBoardView` の incomplete 表示）:
  1. その日付の `Houseworks` ドキュメントは常にそのまま表示する
  2. その日付の曜日に対応するテンプレートアイテムについて、以下を**両方**満たすものを「仮想 incomplete」として追加表示する
     * 表示対象日（0時0分）>= `templateItem.updatedAt` を日付正規化したもの
     * その日付の `Houseworks` に `templateHouseworkItemId == templateItem.id` を持つドキュメントが存在しない
* 「テンプレート適用」概念および Cloud Functions（手動適用用 Callable / 自動適用用 Scheduled）はいずれも廃止する
* `Cohabitant.appliedTemplates` フィールドも不要になるため追加しない

## 考慮した選択肢

* **当初方針（書き込みベース）**: テンプレートを適用すると `Houseworks` に大量書き込みが発生し、編集頻度の高い使い方ではコストが見合わない
* **書き込みベース + バックエンド集約（[ADR-0002](0002-housework-template-apply-on-backend.md)）**: 書き込み発生量の問題は解決せず、Cloud Functions のレイテンシ・コールドスタート・コスト増を追加で背負うことになる
* **仮想ビュー方式（採用）**: テンプレート編集は1ドキュメント書き込みで完了し、`Houseworks` への書き込みは「実際にユーザーが状態遷移させた家事」に限定される。書き込みコストは劇的に下がる

## 決定結果

### 決定にあたり考慮したメリット

* テンプレート編集に伴う `Houseworks` への波及書き込みが完全に消える。Firestore の書き込みコストとクォータ消費が大幅に下がる
* 「テンプレート適用」「上書き確認ダイアログ」「自動適用 Scheduled Function」「`appliedTemplates` のスキップ判定」など、当初設計で必要だった複雑な機構が一括で不要になる
* テンプレートを編集すると即座に翌日以降の `HouseworkBoardView` に反映される（適用操作を挟まない）ためユーザー体験も明快になる
* `templateItem.updatedAt` による表示範囲制御で、テンプレート編集が過去日付に意図せず波及することを防げる
* `templateHouseworkItemId` による紐付けで「テンプレート由来の仮想 incomplete」と「実際に状態遷移して保存された Housework」の重複表示が起きない

### 決定にあたり考慮したデメリット

* `HouseworkBoardView` の表示時に `Houseworks` のフェッチに加えて `HouseworkTemplates/{templateId}/Days` の取得が必要になり、画面側のデータ読み込み・リスナー管理が複雑化する
* マージ表示ロジック（仮想 incomplete の組み立て）をクライアント側で実装する必要がある
* テンプレートに定義された家事を完了させるたびに `Houseworks` ドキュメントの新規作成が発生するため、状態遷移の書き込みパスが「既存ドキュメント更新」から「新規ドキュメント作成」に変わる
* テンプレート由来の家事は完了時点の情報（title・point 等）が `Houseworks` ドキュメントにスナップショットされる挙動になるため、テンプレート側を後から編集しても完了済みの Housework には反映されない（仕様として明示する必要がある）

## 参考

* [家事週間テンプレート機能 対応方針](../strategy/housework_template.md)
* [ADR-0002: 家事テンプレートの手動適用ロジックを Cloud Functions に移行する（却下済）](0002-housework-template-apply-on-backend.md)
* Issue #67: 家事の週間テンプレート機能の追加
* Issue #139: Enhancement: テンプレート手動適用時に Cohabitant.appliedTemplates を更新（本 ADR により対応不要となる）
