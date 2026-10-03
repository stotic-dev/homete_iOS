## タイトル: LocalPackageのテストはローカルではカバレッジなしで流し、CIはmacOS上でテストだけを行う

* **ステータス: 承認済**
* 意思決定者: stotic-dev, Claude Code
* 日付: 2026-10-03
* 関連: [ADR-0011](0011-local-package-lock-instead-of-pkill.md)

## 文脈、背景や問題点の説明

LocalPackageのテストを速くする余地を探るため、`make test-packages` の時間の内訳を測った。テストの実行自体は全6ターゲット合わせても0.1秒未満で、待ち時間のほぼすべてがビルドだった。

さらに、カバレッジの有無（`--enable-code-coverage`）でビルド成果物が別物になり、切り替えるとLocalPackage全体のビルドがやり直しになる。差分ビルドが約20秒で済む状態でも、カバレッジの有無を切り替えた直後は約4分かかる。CIでは `ci_local_package.yml` がiOSシミュレータ向けのビルドとmacOS向けのテストを順に行っており、コンパイルが2回走っている。

ローカル・CIのどちらで、何を削ればテストの待ち時間が減るか？

## 決定事項

* ローカルのテストは `make test-packages-fast`（カバレッジなし。`FILTER=` で対象を絞れる）に統一する。検証スキル・ルール・`.config/wt.toml` の初回ビルドもカバレッジなしに揃え、ローカルでカバレッジの有無が入れ替わらないようにする
* カバレッジ付きの `make test-packages` はCI専用とする（Dangerのカバレッジレポートに必要なため）
* CI（`ci_local_package.yml`）からiOSシミュレータ向けのビルド（`make build-local-package`）を外し、macOS上のテストだけにする

## 考慮した選択肢

* **ローカルもカバレッジ付きのまま、`--filter` だけ足す** — テストの実行時間はもともとほぼゼロのため、絞り込んでも短くならない
* **カバレッジなしのターゲットを足し、従来のターゲットと併用する** — 2つを交互に使うたびに全体のビルドがやり直しになり、かえって遅くなる
* **CIのテストをUbuntuランナーへ移す** — `HometeDomain` からして `SwiftUI` と `AuthenticationServices` をimportしており、Featureのテストもすべて SwiftUI に依存している。依存先のFirebase iOS SDKもLinuxをサポートしておらず、Linuxではビルドできない（SwiftLintPluginのartifactbundleにはLinux版も含まれるので、こちらは障害にならない）。ドメイン層からApple専用フレームワークを外す大規模な改修が前提になるため見送る
* **CIのiOSシミュレータ向けビルドを残す** — iOS限定のコード（`#if os(iOS)`・`canImport(UIKit)` などを含む約40ファイル）を検出できるが、コンパイルが2回走る

## 決定結果

### 決定にあたり考慮したメリット

* ローカルの差分ビルドが、カバレッジの有無を切り替えたときの全体ビルド（約4分）を踏まなくなる
* CIのコンパイルが1回になり、macOSランナーの実行時間が減る

### 決定にあたり考慮したデメリット

* CIでは、iOS限定のコードがコンパイルされなくなる。ローカルでは検証スキルの手順1（`make build-local-package`）で確認するが、それを飛ばした変更は、Xcode Cloudの `VRT`（Feature・HometeUI）や TestFlight へのアップロード（AppRoot・HometeInfrastructure）の時点まで壊れていることに気づかない
* ローカルではカバレッジを見られない。必要な場合はPRのDangerレポートを見るか、一時的に `make test-packages` を流す（流した後の次のローカルビルドは全体のやり直しになる）

## 参考

* [swiftlang/swift docs/Testing.md](https://github.com/swiftlang/swift/blob/main/docs/Testing.md) — Swiftコンパイラ自体のテスト手順。「全体を再ビルドしない」「対象を絞る」という考え方を参考にしたが、lit・build-scriptはSwiftPMのプロジェクトには使えない
