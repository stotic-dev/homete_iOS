---
name: simulator-e2e-check
description: 実装後にシミュレータ（または実機）で homete を起動し、変更した画面を実際に操作して簡易E2E確認を行う。Xcode MCP（xcrun mcpbridge）と device-interaction スキルを使う。「動作確認して」「シミュレータで確認」「実際に動かして」「画面を見て確認」「E2E」と言われたとき、および View / Store / 画面遷移に影響する実装が一通り終わって swift-code-verification を通過した後に使う。ユニットテストやビルドだけの依頼、UIに影響しない変更（リファクタ・ロジックのみ・コメント）では使わない。
---

# シミュレータでの簡易E2E確認

## 位置づけ

ユニットテスト（`make test-packages`）とVRT（CI）は通っていても、「画面遷移がつながっているか」「Firestoreから返ってきたデータが実際に描画されるか」「タップして期待の状態になるか」は実際に動かさないと分からない。このスキルはそこを**ハッピーパス1〜3本**で埋めるためのもので、網羅的なテストではない。

- **swift-code-verification を通過してから使う。** ビルドが壊れている状態でシミュレータを立ち上げても時間を捨てるだけ
- 操作の実行は `device-interaction` スキル（`~/.claude/skills/`。Xcode 27からエクスポートしたもの）に任せる。このスキルは「hometeで動かすための前提・シナリオの決め方・報告」を担当する

## 前提条件（順番に確認する）

満たせないものがあれば**その時点で止めてユーザーに伝える**。回避策を探して時間を溶かさない。

1. **Xcode MCPが使える** — `mcp__xcode__*` ツールが呼べること。呼べなければXcodeが起動していないか、Xcode > Settings > Intelligence でMCPが無効。`xcrun mcp-server status` で状態を確認できる
2. **エージェントがXcodeに承認されている** — 初回は `mcp__xcode__XcodeOpenWorkspace` で**このworktreeの** `homete.xcodeproj`（絶対パス）を開く。これがユーザーへの承認ダイアログを出す。承認前は `XcodeListWorkspaces` すら "This agent isn't approved" で失敗する。戻り値の `workspaceIdentifier`（`workspace-xxxx` 形式）を以降の全ツールで使うので控えておく
3. **`device-interaction` スキルが利用可能** — スキル一覧に無ければ `xcrun agent skills export --output-dir <dir>` で書き出して `~/.claude/skills/` に置く（CLAUDE.md「Xcode同梱スキルの取り込み」参照）
4. **Debug構成 + App Checkデバッグトークン** — `homete/Resouces/Secret_dev.xcconfig` の `APP_CHECK_DEBUG_TOKEN` が未設定だとFirestore・Functionsが全部拒否され、画面にデータが出ない。このファイルはClaudeからは読めない（deny）ので、起動後に一覧が空・エラーが出る場合はまずこれを疑ってユーザーに確認する
5. **iOS 27ランタイムのシミュレータを使う** — `StartWorkspaceSession` はスキームの deployment target を満たすデバイスしか選べない。旧ランタイムのシミュレータ（普段使いのものがそうなら）は指定しても "Cannot select specified device" で弾かれ、候補一覧が返る。Xcode 27 では Simulator.app が **DeviceHub.app**（`<Xcode>.app/Contents/Applications/DeviceHub.app`）に変わっているので、画面を見せたいときは `open -a <そのパス> --args -CurrentDeviceUDID <UUID>`（`open -a Simulator` は失敗する）
6. **ログイン済み・同居人グループ所属済みのアカウント** — Sign in with Apple は自動化できない。起動して `LoginView` が出たら止めて、ユーザーに手動ログインを依頼する（シミュレータの 設定 > Apple Account へのサインインも必要）。パスワードの共有は受けない（トランスクリプトと操作ログに残る上、2FAで結局ユーザー操作が要る）。ログイン状態はシミュレータを消去しない限り再インストールしても残るので、1台で一度やれば済む。
   ログインだけでは足りない点に注意: **家事機能は同居人グループ所属が前提**で、未所属だと家事タブは「グループの登録または参加を行うと…」の案内だけで追加導線が無い。グループ登録の入口は P2P 接続（別端末が必要）なのでこのスキルでは扱わない。新しいシミュレータで初めてログインしたアカウントはほぼ未所属なので、シナリオを組む前にダッシュボードの状態で確認する。状態をリセットする起動引数は付けない

## 手順

### 1. シナリオを決める

`git diff main...HEAD --stat` と変更ファイルから、影響する画面と入口（タブ・遷移元）を特定する。ユーザーがシナリオを指定していればそれに従う。

各シナリオは次の3点を明文化してから始める。曖昧なまま操作すると、報告時に「何を確認したのか」が書けない。

```
入口: ホームタブ → 家事リスト
操作: 「+」をタップ → 名前に「テスト家事」を入力 → 保存
期待: リストに「テスト家事」が追加され、完了ボタンが未完了状態で表示される
```

**やらないこと**
- アカウント削除・同居人グループからの離脱・課金（購入/復元）・実機間のP2P接続を要する操作。これらはSTG Firebaseの実データや他デバイスに影響するので、ユーザーが明示的に頼んだときだけ、確認を取ってから行う
- シナリオを増やして網羅を目指すこと。3本を超えるなら、それはユニットテストかVRTで担保すべき内容

テストで作ったデータ（家事・テンプレートなど）はSTGのFirestoreに残る。シナリオ内で削除できるなら削除まで含め、できなければ報告に「残したデータ」を書く。

### 2. セッションを開く

```
mcp__xcode__DeviceInteractionStartWorkspaceSession
  workspaceIdentifier: <XcodeOpenWorkspaceが返した workspace-xxxx>
  sessionIdentifier: "E2E <機能名>"   # Title Case、ログとXcodeのUIに出る
  deviceIdentifier: 省略（現在のRun Destinationを使う）
```

`workspaceIdentifier` は**IDで渡す**。絶対パスは "Unknown workspace identifier" で弾かれる。worktreeが複数あるので、IDがどのworktreeを指しているかは `XcodeOpenWorkspace` / `XcodeListWorkspaces` の `workspacePath` で確認する（別ブランチのプロジェクトに向いていると、直したはずの挙動が再現しない）。

**セッションの寿命は短い。** 操作が無いまま数分置くと消え、その後のツール呼び出しは "Session with that key doesn't exist" になる。消えた `sessionIdentifier` は "currently in use or was recently used" で再利用できないので、連番や別の語を付けた**新しい名前**で張り直す。実際に消えたケース:

- 初回ビルドが長く `InstallAndRun` が120秒でバックグラウンドに落ちた間
- `LoginView` が出てユーザーに手動ログインを依頼している間

なので「シナリオを書く前に先に呼んでおく」はしない。**`InstallAndRun` とサブエージェント起動を続けて行える状態になってから開く。** ユーザー操作を挟むときは `EndSession` で閉じ、再開時に新しい名前で開き直す（アプリは入ったままなので `InstallAndRun` は速い）。

### 3. ビルド・インストール・起動

```
mcp__xcode__DeviceInteractionInstallAndRun
  interactionSessionKey: <StartWorkspaceSessionの戻り値>
```

`commandLineArguments` / `environmentVariables` は**省略する**。スキーム `homete` に `-AppleLanguages (ja)` と `AppCheckDebugToken=$(APP_CHECK_DEBUG_TOKEN)` が設定されていて、省略すればそのまま引き継がれる。どうしても足す場合は `["$(inherited)", ...]` / `{"$(inherited)": "", ...}` の形にしないと既存の設定が消えてApp Checkが通らなくなる。

初回ビルドは120秒を超えてバックグラウンドタスクに落ちることがある。その場合は完了通知を待ち、失敗していたら（セッションが消えているので）新しい名前でセッションを張り直してからもう一度 `InstallAndRun` する。2回目以降はビルド済みなので数十秒で終わる。

ビルドが失敗したらここで止める（swift-code-verification を通っていれば、たいていメインターゲット側＝`homete/` の問題か署名の問題）。

### 4. 操作と観察（device-interaction サブエージェントに委譲）

`device-interaction` はサブエージェントで動かす設計（スクリーンショットと階層ダンプが大きく、メインのコンテキストを圧迫する）。シナリオごと、または関連するシナリオをまとめて1つのサブエージェントに渡す。

```
Agent tool
  subagent_type: "general-purpose"
  description: "E2E: <シナリオ名>"
  prompt: |
    device-interaction スキルを使って、セッション <session key> 上で以下を確認してください。
    アプリは既に起動しています。まず階層とスクリーンショットを取得してから操作を始めてください。

    入口: ...
    操作: ...
    期待: ...

    各ステップの後に階層を再取得して結果を確認し、最後に
    「ステップごとの結果 / 期待との差分 / 見つけたUI崩れ / 残したデータ」を報告してください。
    ログイン画面が表示されたら操作せずにその旨だけ報告してください。
```

サブエージェントに伝えておくべきhomete固有の注意:

- device-interaction の本文にある `DeviceEventSynthesize` は、実際のツール名は **`mcp__xcode__DeviceInteractionSynthesize`**
- 一覧が空でもすぐバグと判定しない。STGのFirestoreから取得するまで数秒かかるので、スピナーやプレースホルダが消えてから判断する
- 言語は `-AppleLanguages (ja)` で日本語固定。要素のラベルは日本語で探す
- テキスト入力はフィールドをタップしてから `sender keyboard kbd <文字列>`。日本語入力は変換が絡むので、識別できればASCIIの文字列で代用してよい
- 新しいシミュレータでの初回起動は、メイン画面の前に Google UMP の広告同意ダイアログ（英語、"Continue"）→ iOS の ATT ダイアログ（「アプリにトラッキングしないように要求」）が順に出る。どちらも通過してよいと伝えておかないと、そこで止まって報告してくる
- アプリが前面にないときは `activationBundleId: "taichi.satou.hometekure.dev"` を付けて取得する
- OSバージョンは階層やログには出ない。報告用には `StartWorkspaceSession` のデバイス候補一覧（`version: 27.0 (24A434)` のような表記）から取る
- サブエージェントに渡すセッションキーが既に消えている場合、サブエージェントは自力で別名のセッションを張り直せる（`skillToTrigger` の案内どおり）。その場合は報告に新しいキーが載るので、閉じ忘れないよう主エージェント側でも `EndSession` を試す（"Session doesn't exist anymore" なら閉じ済み）

クラッシュや突然の終了が疑われるときは `mcp__xcode__GetConsoleOutput` でアプリのログを取る。

### 5. セッションを閉じる

```
mcp__xcode__DeviceInteractionEndSession
  interactionSessionKey: <session key>
```

**失敗して途中で止めた場合も必ず閉じる。** 開いたままだとXcodeのUIに残り、次のセッション開始にも影響する。

## 報告フォーマット

```
## E2E確認結果（<デバイス名 / iOS バージョン>）

| # | シナリオ | 結果 | 備考 |
|---|---|---|---|
| 1 | 家事の追加 | ✅ | |
| 2 | 完了マーク | ❌ | タップ後にチェックが付かない（下記） |

### 問題
- <シナリオ#> <再現手順> → <実際の挙動>。<コードとの関連の推測があれば1行>

### 確認できなかったこと
- <前提が満たせず飛ばしたシナリオと理由>

### 残したデータ
- STG Firestore に家事「テスト家事」（削除済み / 残っている）
```

結果の判定は device-interaction の「Judging Success vs Failure」に従う。ローディング・キーボードの出入り・権限ダイアログは一時状態であってバグではない。逆に、期待した要素が階層に無い・タップに反応しない・別画面に遷移する・クラッシュは必ず報告する。

サブエージェントの報告は鵜呑みにせず、「期待」と照らして食い違いがあれば問題として書く。確認できなかったことを「問題なし」に丸めない。
