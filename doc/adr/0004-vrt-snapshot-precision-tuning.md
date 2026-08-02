## Xcode Cloud VRT（Prefireスナップショットテスト）の誤検出解消

* **ステータス**: 承認済
* 意思決定者: taichisato（プロダクトオーナー）, Claude（実装・調査担当）
* 日付: 2026-06-27 〜 2026-07-06
* 技術的背景: `hometeSnapshotTests/generateTestTemplate.stencil`（Prefire + swift-snapshot-testing によるVRT）が、ローカルでは100%成功するにも関わらずXcode Cloud上で断続的に失敗する問題への対応

## 文脈、背景や問題点の説明

VRT（Visual Regression Testing）はローカルでは常に成功するが、Xcode Cloud（Apple Silicon Mac上のCI）では見た目上ほぼ差分がないスナップショットが不定期に失敗し続けていた。原因不明のまま複数の対症療法を試みたが再発を繰り返し、最終的に2つの独立した根本原因（色空間の不一致、アンチエイリアス丸めの環境差）を特定して解消した。

## 決定事項

* Prefireの生成テンプレート（`generateTestTemplate.stencil`）側で、スナップショットの**レンダリング色空間をsRGBに固定**する（`displayGamut: .SRGB`）。ローカルMacがDisplay P3で参照画像を記録することによる色空間不一致を解消するため。
* テンプレート側で `perceptualPrecision` を**一律 `min(値, 0.98)` でキャップ**する。`precision`（許容ピクセル割合）は緩和しない。CIとローカルで発生する図形エッジの±1/255丸め差（知覚不能）だけを吸収し、知覚可能な変化は従来通り検出する。
* Preview個別の `.snapshot(precision:)` 系モディファイアの値は尊重しつつ、テンプレート側の上限でラップする方式に統一する（Preview個別指定 + テンプレート一律キャップの併用）。

## 考慮した選択肢（試行の時系列）

長期間にわたり複数の仮説→対策→再発のサイクルを経ている。時系列で記録する。

| # | 日付 | コミット | 試行内容 | 結果 |
|---|------|----------|----------|------|
| 1 | 06/27 | `e936468` | `drawHierarchyInKeyWindow` を有効化 | 解消せず |
| 2 | 06/27 | `4bec296` | Liquid Glass表示をスナップショット時に非表示化 | 解消せず |
| 3 | 06/27 | `644bd34` | Chart/Setting系Previewに `.compositingGroup()` 追加、LoadingIndicatorをVRT対象外に | 部分的に改善するが根本解決せず |
| 4 | 06/28 | `779ae06` | 失敗する12個のPreviewに個別で `precision/perceptualPrecision: 0.85` を適用（Xcode Cloud側がM2 Ultra Virtual、ローカルがM4というGPU世代差が原因と仮説） | 再発 |
| 5 | 06/28 | `7ff72d5` | Chart表示に描画待ちのdelayを追加 | 再発 |
| 6 | 06/28 | `634d251` | destructiveボタンの色変更 | 再発 |
| 7 | 06/29 | `d2bd1b3` | Preview個別の `.snapshot(precision:)` は `onPreferenceChange` がheadlessテスト環境で同期発火せず伝播しないと判断し、テンプレート側で一律 `precision: 0.85` に固定。Preview側の指定は全て削除 | 一時的に安定 |
| 8 | 06/29 | `9b2eeb3` | precision緩和の代替として2秒delayを追加する案を試行 | 効果不十分 |
| 9 | 07/04 | `aff5c3e` | 上記delay案をrevert | - |
| 10 | 07/04 | `f7ec638` | Prefireのsnapshotモディファイア周りを修正 | - |
| 11 | 07/06 | `8f0781c` | **根本原因1を特定**: ローカルMac（Display P3）が参照PNGをP3でエンコードする一方、Xcode CloudのシミュレータはsRGBでレンダリングしていた。swift-snapshot-testingの知覚比較はカラーマネジメント無効で生ピクセル値を比較するため、彩度の高い色（チャート線・ボタン等）で誤検出が発生していた（CIログの一致率 `0.9422` をP3→sRGB変換で数値再現し実証）。対策: `displayGamut: .SRGB` 固定 + 参照PNG 216枚をsRGBで再記録。合わせてGPU差の保険として `precision/perceptualPrecision` に暫定で0.95の上限を適用 | ローカルVRT 108件成功 |
| 12 | 07/06 | `28b06c4` | Xcode CloudもApple Silicon MacでGPU差がないとの判断から、暫定的な0.95上限を撤廃し、Preview個別指定の値をそのまま使う方式に戻す | ローカル108件成功もXcode Cloud Build 195で4件失敗 |
| 13 | 07/06 | `492e128` | **根本原因2を特定**: Build 195の失敗4件を解析した結果、いずれも図形エッジのアンチエイリアス画素が1チャンネルだけ±1/255ずれる丸め差（deltaE < 0.5、差分ピクセル数は画像あたり1〜6個）であることが判明。ローカルとCIはiOS runtime（`24A5370g`）・macOS（26.5.1）とも完全一致しており、アーキテクチャ差ではなく、同一Apple Silicon内でもGPU世代差や浮動小数点演算順序の違いによりアンチエイリアスのカバレッジ値が量子化境界付近でLSBが変わることが原因と判断。対策: `perceptualPrecision` を一律 `min(値, 0.98)`（deltaE≤2、知覚限界未満）でキャップ。`precision` は緩和しないため知覚可能な変化は全ピクセルで引き続き検出される | ローカルVRT 108件成功、Xcode Cloud再実行待ち |

## 決定結果

### 決定にあたり考慮したメリット

* 色空間統一（sRGB固定）は誤検出の最大要因を構造的に解消し、以後は「本当に見た目が変わったか」の検出に集中できる。
* `perceptualPrecision` のみを緩和し `precision`（ピクセル割合条件）を保つことで、知覚可能な回帰は引き続き100%検出しつつ、環境依存の丸め誤差だけを許容する。閾値0.98（deltaE≤2）は人間の知覚限界未満であり、見た目の破壊的変更を見逃すリスクは実質的にない。
* Preview個別の `.snapshot()` 指定を尊重しつつテンプレート側で上限をかける方式のため、意図的に精度を落としたいPreview（複雑なチャート等）の柔軟性も維持される。

### 決定にあたり考慮したデメリット

* 「アーキテクチャが揃えばビット完全一致する」という前提は誤りだった。同一Apple Silicon・同一iOS runtime・同一macOSでも、GPU世代差や浮動小数点演算順序の違いにより最終ビットの丸めは環境依存で変わり得る。`precision: 1.0`（完全一致）を要求する限りこの種の誤検出は原理的に排除できないため、今後もCI環境の変化（Xcodeバージョン更新、macOSアップデート等）で新たな±1差が出る可能性は残る。
* 手順6〜10（06/28〜07/04）の試行はいずれも対症療法であり、根本原因の特定前に個別Previewの色変更やdelay追加などプロダクションコード側に手を入れてしまっている。結果的に不要だった変更が混在している可能性がある。
* 過去のコミットメッセージ（`d2bd1b3`）に残る「Preview個別の`.snapshot(precision:)`は伝播しない」という記述は、その後の調査で誤りと判明した（実際には`preferences`経由で正しく伝播する）。過去の判断記録を鵜呑みにせず、疑わしい場合は実測で検証する必要がある。

## 参考

* `hometeSnapshotTests/generateTestTemplate.stencil` — 最終的な実装（displayGamut固定 + perceptualPrecision 0.98キャップ）
* swift-snapshot-testing の `perceptuallyCompare` 実装（`UIImage.swift`）: CoreImageの `CILabDeltaE` フィルタでdeltaE（0-100）を計算。`deltaThreshold = (1 - perceptualPrecision) * 100`
* 関連コミット: `e936468`, `4bec296`, `644bd34`, `779ae06`, `7ff72d5`, `634d251`, `d2bd1b3`, `9b2eeb3`, `aff5c3e`, `f7ec638`, `8f0781c`, `28b06c4`, `492e128`
