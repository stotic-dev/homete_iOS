## タイトル: ダッシュボードのねぎらいコメントは端末内のFoundation Modelsで生成し、使えないときは固定文言を出す

* **ステータス**: 承認済
* 意思決定者: taichisato（プロダクトオーナー）, Claude（調査・実装担当）
* 日付: 2026-10-06
* 技術的背景: [#354](https://github.com/stotic-dev/homete_iOS/issues/354)（家事の実施状況に応じたポジティブなコメント）、[#400](https://github.com/stotic-dev/homete_iOS/issues/400)（Private Cloud Computeのentitlement申請）
* 実装方針: [doc/strategy/encouragement-comment.md](../strategy/encouragement-comment.md)

## 文脈、背景や問題点の説明

家事の記録は「やった/やらない」の事実として残るだけで、本人への肯定や同居人への感謝を引き出す仕組みが弱い。そこでダッシュボードに、家事の実施状況からパーソナライズしたねぎらいのコメントを出す。

コメントには家事のタイトル・件数・同居人ごとの実績が入る。**同居人の家事内容をどこで処理し、どう出力のトーンを守るか？**

## 決定事項

* **ねぎらいのコメントは、端末内のFoundation Models（`SystemLanguageModel`）で生成する。**
  * 入力は、自分の実績・今日の家事サマリー・今月のメンバー別の貢献度（`EncouragementContext`）。未完了の家事のタイトルや件数は渡さない
  * 生成するのは「取りかかり中」「今日の家事が全部完了」の節目ごとに1回（1日最大2回）で、結果は`UserDefaults`にキャッシュする
* **Foundation Modelsを使えないときは、あらかじめ用意した固定文言を出す。** 対象は、iOS 26未満・非対応端末・Apple Intelligenceがオフ・モデルの準備中・日本語非対応・生成エラー・タイムアウト（10秒）
* **トーンは2段で守る。** instructionsで比較・要求・指摘をしないよう指示したうえで、生成結果を禁止表現リスト（`EncouragementToneValidator`）で検証し、引っかかったら固定文言に切り替える。固定文言も同じ検証を通ることをユニットテストで担保する
* **同居人への感謝の促しはLLMで生成しない。** 件数入りの固定テンプレートにして、ありがとうを送るたびにその場で件数を更新する
* **Private Cloud Compute（`PrivateCloudComputeLanguageModel`）は初回リリースでは使わない。** entitlementの申請と、iOS 27 SDKでのビルド環境が必要なため、#400で追加する

## 考慮した選択肢

* A. ルールベースのテンプレートだけで生成する
* B. 端末内のFoundation Modelsで生成し、固定文言にフォールバックする（採用）
* C. サーバー側のLLM（Cloud Functions経由で外部API）で生成する
* D. Private Cloud Computeで生成し、端末内モデル → 固定文言の順にフォールバックする

## 決定結果

### 決定にあたり考慮したメリット

* 家事の内容が端末の外に出ないため、プライバシーポリシーの追記や外部APIの規約対応が要らない（Cとの比較）
* 費用がかからず、オフラインでも動く。App Checkやcallable関数を新たに用意する必要もない（Cとの比較）
* テンプレートより自然で、その日の実績に合わせた文になる（Aとの比較）
* entitlementの付与を待たずにリリースできる。Dの`LanguageModelSession(model:)`は同じセッションAPIでモデルを差し替えるだけなので、後から追加しやすい

### 決定にあたり考慮したデメリット

* Apple Intelligenceに対応していない端末では、いつも固定文言になる
* LLMの出力は完全には制御できない。禁止表現の検証は語句の一致で判定するため、「〇〇さんのほうがたくさん」のような言い回しの比較は防ぎきれないことがある。メンバー別の実績を渡すと決めたため、このリスクは自分の実績だけを渡す場合より高い。リリース前に、偏りの大きいデータで出力を確認する
* 生成結果はユニットテストで検証できない。テストでは生成Clientをモックに差し替え、出し分けとフォールバックだけを検証する
* アプリのデプロイターゲットがiOS 17のため、`#if canImport(FoundationModels)`と`#available(iOS 26, *)`で分ける必要がある

## 参考

* [Foundation Models | Apple Developer Documentation](https://developer.apple.com/documentation/foundationmodels)
* [ADR-0009 Analyticsイベントのパラメータ設計](0009-analytics-event-parameter-design.md)
