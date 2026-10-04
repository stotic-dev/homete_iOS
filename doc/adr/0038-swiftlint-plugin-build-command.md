## タイトル: SwiftLintPluginをprebuildCommandからbuildCommandに変え、変更のあったターゲットだけをlintする

* **ステータス: 承認済**
* 意思決定者: stotic-dev, Claude Code
* 日付: 2026-10-03
* 関連: [ADR-0037](0037-local-package-test-without-coverage-and-ci-test-only.md)

## 文脈、背景や問題点の説明

`make test-packages-fast` は、コードを変えずに再実行しても約200秒かかっていた。内訳はビルドが10秒前後、テストは1秒未満で、残りはビルドが始まる前の時間だった。`swift build -v` で見ると、その間 `Running SwiftLint <ターゲット>` が全19ターゲット分、順番に並んでいた。

`ProjectTools/Plugins/SwiftLintPlugin` は `.prebuildCommand` でlintを登録している。prebuildCommandは入出力を宣言できないため、変更の有無にかかわらず**ビルドのたびに全ターゲットで直列に**走る。SwiftLintのキャッシュは効いていたが、1回起動するだけで約1.2秒かかり、それが毎回19回積み上がっていた。

## 決定事項

* SwiftLintPluginを `.buildCommand` に変え、入力（ターゲットのSwiftファイル・`.swiftlint.yml`・swiftlint本体）と出力（lintが通った印のファイル）を宣言する。入力が変わったターゲットだけがlintされ、複数ターゲットは並列に走る
* 印のファイルは、ターゲットにコンパイルされる空のSwiftファイル（`<ターゲット名>+SwiftLintStamp.swift`）にする。buildCommandはビルドがその出力を使うときしか実行されず、Swift以外の出力はリソース扱いになるため
* lintが失敗したら印を更新しない。次のビルドでも同じターゲットのlintが走り、エラーが出続ける

## 考慮した選択肢

* **prebuildCommandのまま（現状）** — 何も変えずに再実行しても毎回1〜2分かかる
* **LocalPackageからSwiftLintPluginを外し、lintはpre-commitやCIで流す** — 最も速いが、ビルドしただけでlintが走るという今の運用が変わり、ビルドログで警告を見られなくなる
* **buildCommandにする（採用）** — 運用は変えずに、変更のないターゲットのlintを省ける

## 決定結果

### 決定にあたり考慮したメリット

* 何も変えずに `make test-packages-fast` を再実行したときの時間が、約200秒から約20秒になった
* lintのエラーは今までどおりビルドを失敗させ、警告もビルドログに出る

### 決定にあたり考慮したデメリット

* 警告が出るのは、そのターゲットがlintされたビルドだけになる。変更していないターゲットの既存の警告は、2回目以降のビルドでは表示されない。全体の警告を見たいときは `swiftlint lint` を単体で流す
* 各ターゲットに空のSwiftファイルが1つずつコンパイルされる
* lintが失敗したときのエラー出力に、`/bin/sh -c` のコマンドラインがそのまま表示されて読みにくい

## 追記（2026-10-04）: スクリプトを `/bin/sh -c` の引数で渡すのをやめた

この決定でbuildCommandに変えたとき、lintの実行を `/bin/sh -c '<スクリプト>' swiftlint-plugin <引数...>` の形にし、スクリプトの中で `$1`〜`$3`・`$@` を使っていた。これが原因で、Xcodeでアプリ（`homete`ターゲット）をビルドすると `swiftlint-plugin: line 1: : command not found` で失敗するようになった（Xcodeのバージョンによらず再現する）。

XcodeはbuildCommandを`sandbox-exec`で包んだシェルスクリプトに書き出し、その中で`-c`のスクリプトを`$`をエスケープせずに二重引用符へ入れる。そのため、引数なしで走る外側のスクリプトが`$1`などを先に展開して空にし、`"" lint ...`が実行されていた。`swift build`は引数をそのまま実行するので、ターミナルからのビルド・テストでは再現せず、変更時に気づけなかった。prebuildCommandだった頃はswiftlint本体を直接実行しており、引数に`$`を含まなかったので起きていない。

スクリプトはプラグインの作業ディレクトリに`swiftlint-plugin.sh`として書き出し、`/bin/sh <スクリプトのパス> <引数...>`で実行するようにした。引数がパスだけになるので、Xcodeがどう包んでも展開されない。スクリプトはlintの入力にも含めるので、内容が変わったときだけ書き込む（毎回書き直すと更新日時が変わり、全ターゲットのlintが走り直すため）。

プラグインを変えたときは、`swift build`だけでなくXcodeでのアプリのビルドも確認すること。
