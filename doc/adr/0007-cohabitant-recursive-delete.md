## Cohabitant削除時のサブコレクション削除方式: recursiveDeleteを採用する

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-08-09
* 技術的背景やその他関連チケット No: [#192](https://github.com/stotic-dev/homete_iOS/issues/192)

## 文脈、背景や問題点の説明

Firestoreは親ドキュメントを削除してもサブコレクションを削除しない。そのため退会時の `deleteuserdata` は、`Cohabitant/{id}` 配下のサブコレクションを明示的に列挙して削除していた。

しかしその列挙リスト（`Housework` / `HouseworkHistory`）はクライアントが実際に書き込む名前（`Houseworks` / `HouseworkTemplates`）と一致しておらず、家事データが一切削除されていなかった。さらに悪いことに、E2Eテストがプロダクションコードと**同じ定数**を参照していたため、名前がズレていてもテストは緑のままだった。

同じ事故を再発させないために、どう削除するかを決める必要がある。

## 決定事項

* `Cohabitant` グループ削除時は `Firestore.recursiveDelete(cohabitantRef)` を使い、ドキュメントとその配下すべてを一括で削除する
* サブコレクション名をFunctions側で列挙する実装（`removeCohabitantSubcollections` / `batchDeleteCollection`）は廃止し、`FirestoreCollections` からも家事系の定数を削除する
* E2Eテストが使うコレクション名は、プロダクションコードの定数を参照せず `test/helpers/clientCollections.ts` に**独立して定義**する。これは `CollectionPath.swift` を写したもので、意図的な重複によりクライアントとの名前の一致を検証する

## 考慮した選択肢

* **選択肢1: 列挙リストを正しい名前に修正し、`HouseworkTemplates` のネスト（`Days` / `Editors`）分の再帰処理を足す**
  * Issue #192 に記載されていた当初の対応案
* **選択肢2: `recursiveDelete` に置き換える（採用）**

## 決定結果

### 決定にあたり考慮したメリット

* クライアントがサブコレクションを追加しても、Functions側の修正漏れで消し残しが発生しない。今回のバグの原因そのものを構造的に取り除ける
* ネストの深さに依存しないため、`HouseworkTemplates/{id}/Days` のような多階層を手で再帰する実装が不要になり、コードが約60行減る
* プロダクションコードがコレクション名を持たなくなるので、E2Eテストが独立した名前定義を使わざるを得なくなる。結果として「テストと実装が同じ間違いを共有する」構図が成立しなくなる
* `recursiveDelete` は内部でBulkWriterを使うため、従来の500件バッチ手動再帰と同等以上のスループットが出る（600件のE2Eケースで確認済み）

### 決定にあたり考慮したデメリット

* 削除対象が暗黙的になり、「何が消えるか」がコードから読み取れなくなる。グループ削除は全消しが期待動作なので許容するが、将来一部だけ残す要件が出たら方式を見直す必要がある
* `recursiveDelete` はアトミックではなく、途中で失敗すると部分削除の状態が残りうる。ただし従来のバッチ削除も同様で、後退はしていない
* Firestoreエミュレーターでの動作保証が必要。E2Eテストで実際に検証済み

## 参考

* [Firestore: Delete data - recursiveDelete](https://firebase.google.com/docs/firestore/manage-data/delete-data)
* `firebase/functions/src/deleteUserData.ts`
* `firebase/functions/test/helpers/clientCollections.ts`
* `LocalPackage/Sources/HometeInfrastructure/Firestore/Reference/CollectionPath.swift`
