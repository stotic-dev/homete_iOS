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
2. **エージェントがXcodeに承認されている** — 初回は `mcp__xcode__XcodeOpenWorkspace` で**このworktreeの** `homete.xcodeproj`（絶対パス）を開く。これがユーザーへの承認ダイアログを出す。承認前は `XcodeListWorkspaces` すら "This agent isn't approved" で失敗する
3. **`device-interaction` スキルが利用可能** — スキル一覧に無ければ `xcrun agent skills export --output-dir <dir>` で書き出して `~/.claude/skills/` に置く（CLAUDE.md「Xcode同梱スキルの取り込み」参照）
4. **Debug構成 + App Checkデバッグトークン** — `homete/Resouces/Secret_dev.xcconfig` の `APP_CHECK_DEBUG_TOKEN` が未設定だとFirestore・Functionsが全部拒否され、画面にデータが出ない。このファイルはClaudeからは読めない（deny）ので、起動後に一覧が空・エラーが出る場合はまずこれを疑ってユーザーに確認する
5. **ログイン済みの端末を使う** — Sign in with Apple は自動化できない。普段使っているシミュレータ（ログイン済み・同居人登録済み）をそのまま使う。起動して `LoginView` が出たら止めて、ユーザーに手動ログインを依頼してから再開する。状態をリセットする起動引数は付けない

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
  workspaceIdentifier: <このworktreeの絶対パス>/homete.xcodeproj
  sessionIdentifier: "E2E <機能名>"   # Title Case、ログとXcodeのUIに出る
  deviceIdentifier: 省略（現在のRun Destinationを使う）
```

worktreeが複数あるので `workspaceIdentifier` は必ず**絶対パス**で渡す。相対指定や省略だとXcodeで最後に開いたプロジェクト（別ブランチの可能性がある）に向く。

デバイスの起動に時間がかかるので、シナリオを書き出す前に先に呼んでおいてよい。

### 3. ビルド・インストール・起動

```
mcp__xcode__DeviceInteractionInstallAndRun
  interactionSessionKey: <StartWorkspaceSessionの戻り値>
```

`commandLineArguments` / `environmentVariables` は**省略する**。スキーム `homete` に `-AppleLanguages (ja)` と `AppCheckDebugToken=$(APP_CHECK_DEBUG_TOKEN)` が設定されていて、省略すればそのまま引き継がれる。どうしても足す場合は `["$(inherited)", ...]` / `{"$(inherited)": "", ...}` の形にしないと既存の設定が消えてApp Checkが通らなくなる。

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
