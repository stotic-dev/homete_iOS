## タイトル: VRT専用のXcodeプロジェクトを作り、VRTが重い外部依存を解決しないようにする

* **承認済**
* 意思決定者: stotic-dev
* 日付: 2026-10-17
* 関連: [ADR-0029](0029-vrt-dedicated-host-app-target.md)、[ADR-0046](0046-split-infra-package-from-local-package.md)、Issue #444

## 文脈、背景や問題点の説明

ADR-0029でVRTのテストホストを空のアプリ`hometeVRTHost`に替え、VRTのビルドからFirebaseなどを外した。
しかし、Xcodeはパッケージの依存を**スキーム単位ではなくプロジェクト単位**で解決する。VRTを`homete.xcodeproj`で
動かす限り、アプリが参照するパッケージはすべて取得される。git clone、チェックアウト、grpc・abseil・Firestoreなどの
xcframeworkのダウンロードが、VRTのたびに発生していた。

ADR-0046で重い外部依存をInfraPackageに分けたので、VRTが必要とするLocalPackageには、もう重い依存が無い。

## 決定事項

* リポジトリ直下にVRT専用の`hometeVRT.xcodeproj`を作る。持たせるのは`hometeVRTHost`・`hometeSnapshotTests`の
  2ターゲットと、`hometeSnapshotTests`スキームだけ
* `hometeVRT.xcodeproj`が参照するパッケージは`LocalPackage`だけにする（InfraPackage・ProjectToolsは参照しない）
* 2ターゲットとスキームは`homete.xcodeproj`から削除する。テストプラン（`snapshotTesting` / `hometeSnapshotTestsForCI`）は
  `hometeVRT.xcodeproj`のターゲットを指すようにする
* オブジェクトIDは`homete.xcodeproj`のものを引き継ぐ。スキーム・テストプランが参照するターゲットIDが変わらないようにするため
* `hometeVRT.xcodeproj`はリポジトリ直下に置く。Xcode Cloudはプロジェクトと同じ階層から`ci_scripts/`を探すので、
  既存のスクリプトと`.prefire.yml`の`${PROJECT_DIR}`をそのまま使える
* Xcode Cloudの`VRT`ワークフローの参照先は、App Store Connectで`hometeVRT.xcodeproj`に切り替える（手作業）

## 考慮した選択肢

* **homete.xcodeprojのままにする**: 構成は単純だが、VRTの依存解決は減らない
* **ワークスペース（.xcworkspace）でまとめる**: ワークスペースも、含まれるすべてのプロジェクトの依存をまとめて解決するので、
  VRTに効果が無い
* **VRT専用のプロジェクトを作る（採用）**

## 決定結果

VRTが解決するパッケージは、`homete.xcodeproj`の24個から6個（Prefire・swift-snapshot-testing・SwiftGenPluginと、
それらが依存するもの）に減った。

### 決定にあたり考慮したメリット

* VRTがFirebase・AdMob・RevenueCat・GRDBを取得しなくなる
* アプリのプロジェクトからVRTのターゲットが消え、アプリのスキームのテストに紛れていた`hometeSnapshotTests`も外れる
* アプリのResourcesに紛れ込んでいた`snapshotTesting.xctestplan`も、このとき外した

### 決定にあたり考慮したデメリット

* Xcodeのプロジェクトと`Package.resolved`が1つずつ増える。`hometeVRT.xcodeproj`の`Package.resolved`は、
  `LocalPackage/Package.resolved`と同じバージョンにそろえて作った。dependabotはプロジェクト側の`Package.resolved`を
  更新しないので、LocalPackageの依存を上げたときは、`homete.xcodeproj`側と同じく手で解決し直す必要がある
* ローカルでVRTを動かすときは`hometeVRT.xcodeproj`を開く。同じLocalPackageを参照するので、`homete.xcodeproj`と
  同時には開けない（Xcodeは1つのローカルパッケージを1つのウィンドウでしか開けない）
* Featureを足したときにリンク設定を更新する先が、`hometeVRT.xcodeproj`の`hometeSnapshotTests`になる

## 参考

* [ADR-0029](0029-vrt-dedicated-host-app-target.md)
