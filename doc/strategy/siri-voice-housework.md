# Siriへの音声入力で家事を記録・登録する 実装方針

> 関連Issue: [#468 Siriの音声入力で家事を記録・登録できるようにする（App Intentsのスキーマ対応）](https://github.com/stotic-dev/homete_iOS/issues/468)
> ブランチ: `feat/468-siri-voice-input`
> 土台: [ADR-0044](../adr/0044-app-intents-headless-usecase-and-title-keyed-entity.md)、[app-intents-donation.md](app-intents-donation.md)

## ステータス

- [x] 要件確定（iOS 17〜の側）
- [ ] スパイク（iOS 27.2の日本語Siri AI実機で`.reminders`スキーマを試す）
- [x] iOS 17〜の側の実装完了
- [x] テスト追加完了
- [ ] 実機での動作確認
- [ ] iOS 27〜の側（スキーマ）の実装
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

家事を登録・記録する手間を減らすため、Siriに家事の名前を伝えるだけで記録・登録できるようにする。

- 記録（やった家事）: 「洗濯干したから記録しておいて」
- 登録（これからやる家事）: 「買い物行くから登録しておいて」

Issueでは2本立てにしている。このドキュメントの範囲は**iOS 17〜の側**（App Shortcuts。アプリ名を言う）。
アプリ名なしで呼べるiOS 27〜の側（`.reminders`スキーマ）は、実機のスパイクで採用を決めてから進める。
Pdmレビューのとおり、iOS 17〜の側は対応端末の制約がなく、スパイクを待たずに進められるため先に入れる。

## 要件

### 未決事項の決定

Issueの未決事項1〜4は、次のように決めた。スパイクの結果やレビューで変える余地がある。

| # | 論点 | 決定 | 理由 |
|---|---|---|---|
| 1 | 新しく登録するときのポイント | 初期値（10pt）にする。聞き返さない | 登録画面の「新しく入力」と同じ初期値。音声のやり取りを増やさない。あとからアプリで変えられる |
| 2 | 新しく登録するときに確認するか | 確認する（記録・登録の両方） | 音声の聞き間違いで、別の名前の家事を作らないため |
| 3 | 今日の家事に同じ家事があるときの登録 | 未完了なら重ねて登録せず「もうあります」と返す。終わっているだけなら、もう一度やるものとして登録する | 同じ家事が並ぶのを防ぐ。終わった家事をもう一度やるのは自然な使い方 |
| 4 | 新しく登録した家事を、いつもの家事にも追加するか | 追加しない | いつもの家事は上限があり、意図せず増えると整理の手間になる。追加は画面から行う |
| 5 | 実行した人・通知 | 話しかけた本人を担当者にする。同居人への完了通知は既存の完了と同じ条件で送る | Issueの前提どおり |
| 6 | 今日もう終わった家事をもう一度記録するか | 記録しない（「もう終わっています」と返す） | 既存の`CompleteHouseworkIntent`と同じ。Siriの誤作動で二重に記録されるのを防ぐ。1日に何度もやる家事は、アプリの「もう一回やった」で記録する |

### 機能要件

#### Intent一覧

| Intent | アプリを開くか | 引数 | 結果 |
|---|---|---|---|
| `RecordHouseworkIntent`（やった家事を記録する） | 開かない | 家事の名前（必須） | 「おつかれさまでした。洗濯物干しを記録しました（+30pt）」 |
| `RegisterHouseworkIntent`（これからやる家事を登録する） | 開かない | 家事の名前（必須）・メモ（任意） | 「今日の家事に買い物を追加しました」 |

どちらもApp Shortcutsに登録する（「${applicationName}で家事を記録」「${applicationName}で家事を登録」など）。
App Shortcutsのフレーズには自由入力の文字列を入れられないため、家事の名前はSiriが「どの家事をしましたか？」と聞き返して受け取る。

#### 記録（やった家事）

1. 今日の家事（テンプレートの家事を含む）に、同じ名前の未完了の家事があれば、それを完了にする
2. 同じ名前の家事が今日はもう終わっていれば、「洗濯物干しはもう終わっています」と返して何もしない
3. 今日の家事に同じ名前が無ければ、名前が似ている今日の未完了の家事と、いつもの家事を探す（今日の家事を先に並べ、同じ名前のいつもの家事は除く）
   - 1件なら「今日の家事の『洗濯物干し』を完了にしますか？」「いつもの家事の『洗濯物干し』を完了にしますか？」と確認する（`requestConfirmation`）
   - 複数なら、候補と「『洗濯干した』を新しく登録する」を並べて選んでもらう（`requestDisambiguation`）
   - 選んだ家事が今日の家事に未完了であればそれを完了にし、無ければいつもの家事のポイント・メモで今日の家事に作って完了にする
   - テンプレートから出している家事がいつもの家事に無くても、言い方の揺れで新しい家事を作らないようにするため、今日の家事も候補にする
4. いつもの家事にも無い（または確認に「いいえ」と答えた）ときは、「『洗濯干した』を新しく登録して、記録しますか？」と確認し、10ptで作って完了にする。「いいえ」なら「記録しませんでした」と返す
5. 担当者は自分だけ、頑張り度は「ふつう」にする（既存の`CompleteHouseworkIntent`と同じ）

#### 登録（これからやる家事）

6. 今日の家事に同じ名前の未完了の家事があれば、「買い物は、今日の家事にもうあります」と返す
7. いつもの家事から名前が似ている家事を探し、記録と同じく確認・選択してもらう。選んだらそのポイント・メモで登録する
8. いつもの家事に無ければ（「いいえ」と答えたら）、「『買い物』を新しく登録しますか？」と確認し、10ptで登録する
9. メモの引数（「牛乳と卵」）は家事のメモのテキストに入れる。いつもの家事のメモがあれば、その後ろに改行して足す
10. メモの引数がプランで書ける文字数を超えていれば登録しない（いつもの家事のメモは保存したときに確かめ済みなので数えない）。聞き返しの後に断らないよう、候補を探す時点で確かめる
11. 登録は同居人へ通知しない（家事の追加画面と同じ）

#### 名前の似ている判定

12. 空白・カタカナとひらがな・全角と半角・大文字と小文字の違いはそろえて比べる（「ゴミ出し」と「ごみ出し」は同じ）
13. そろえた名前が同じいつもの家事があれば、その家事だけを候補にする
14. 片方がもう片方を含めば似ている（1文字の名前は何にでも含まれやすいので除く）、それ以外は2文字ずつの組（バイグラム）の重なり（Dice係数）が0.4以上なら似ているとみなす。候補は似ている順に最大5件
    - 「洗濯干した」→「洗濯物干し」（0.5）、「洗濯物を干した」→「洗濯物干し」（0.6）、「買い物行く」→「買い物」（含む）

#### 共通

15. ログインしていない・グループに所属していない・強制アップデートが必要なバージョンのときは、既存のIntentと同じ文言を返す
16. 端末がロックされているときは解除を求める（`authenticationPolicy = .requiresAuthentication`）
17. 通信できないときは10秒だけ書き込みを待ち、「オンラインになってから反映されます」と返す（既存のIntentと同じ）
18. 確認・選択をユーザーが選ばずに閉じたときは、実行の失敗として数えない
19. ショートカットAppで候補（引数「家事の候補」）を指定して実行したときは、聞き返さずにその家事を記録・登録する

### スコープ外（スパイクの後に判断する）

- iOS 27〜の`.reminders`スキーマのIntent（`@AppIntent(schema: .reminders.updateReminder)` / `createReminder`、`isAssistantOnly = true`）
- `@AppEntity(schema: .reminders.reminder)` / `.reminders.list`のEntity
- いつもの家事のSpotlightへのインデックス（`IndexedEntity`。Apple Intelligenceの意味検索で、曖昧な言い方から家事を見つけるため）
- スキーマ採用のADR
- アプリの中での記録・登録のドネーション。今回のIntentはSiriから使うたびにOSが自動で記録し、App ShortcutsとしてSpotlightにも出る

## 設計方針

### 1. 書き込みは`HouseworkCommandUseCase`で共有する

完了は既存の`HouseworkCommandUseCase.complete`を使う。登録は`HouseworkListStore.register`の書き込み・Analyticsを`HouseworkCommandUseCase.register`へ切り出し、
StoreとIntentの両方から呼ぶ（挙動を変えないリファクタリングとして先にコミットする）。

今日の家事に無い家事を記録するときは、未登録の家事（テンプレートの家事と同じ扱い）として作り、`complete(isRegistered: false)`で1回の書き込みで完了にする。
Analyticsは`housework`の`complete`だけ送り、`register`は送らない（記録は「完了」の操作で、登録画面を通った登録と混ぜないため）。

### 2. 探す処理と書き込みを分ける

Siriの聞き返しはIntentの型（`$parameter.requestConfirmation`など）が必要なため、`HouseworkIntentService`は次の2段に分ける。

| メソッド | 役割 |
|---|---|
| `voicePlan(title:now:)` | 今日の家事の同じ名前の家事（`TodayHouseworkMatch`）と、似ているいつもの家事（`suggestions`）を返す |
| `recordHousework(_:now:)` / `registerHousework(_:note:now:)` | 選んだ家事（`VoiceHouseworkTarget`）を、取り直した今日の家事に当てて書き込む |

Intentは`voicePlan`の結果で確認・選択を行い、選んだ家事を渡す。書き込む側は聞き返しの間に同居人が変えた分を拾うため、今日の家事といつもの家事を取り直す。
いつもの家事が消されていたら、名前だけの家事として扱う。

### 3. いつもの家事の取得

いつもの家事はスナップショットリスナーでしか読めないため、`AppIntentSessionUseCase.fetchFrequentHousework`で最初に届いた値だけ使って購読をやめる（グループのメンバーの取得と同じ）。
最初の値は端末のキャッシュのことがあるが、提案に使うだけなので待たない。

### 4. 候補のEntity

`HouseworkSuggestionEntity`は、今日の家事（`today:<名前>`）・いつもの家事（`frequent:<ID>:<名前>`）・「話した名前のまま新しく登録する」（`title:<名前>`）の3種類をIDで表す。
IDに名前を含め、サーバーに問い合わせずにIDから候補へ戻せるようにする（聞き返しの間にいつもの家事が消されても、名前だけの家事として扱える）。
`requestDisambiguation`に「新しく登録する」も並べ、候補に無いときの逃げ道にする。

### 5. 文言

- Intentのタイトル・説明・引数名・`requestValueDialog`・Entityの型名・App Shortcutsの短い名前は、アプリ本体の`homete/Resouces/Localizable.xcstrings`に日英で入れる（`extractionState: manual`）
- 実行時のダイアログは`.localized`で`HometeAppIntents`の`Localizable.xcstrings`から引く
- フレーズは`homete/Resouces/AppShortcuts.xcstrings`

## タスク

- [x] `HouseworkCommandUseCase.register`の切り出し（refactor）
- [x] 名前の似ている判定（`HouseworkTitleSimilarity`・`FrequentHouseworkContext.similarItems`）とテスト
- [x] `AppIntentSessionUseCase.fetchFrequentHousework`
- [x] `HouseworkIntentService`の記録・登録と、テスト
- [x] `RecordHouseworkIntent`・`RegisterHouseworkIntent`・`HouseworkSuggestionEntity`
- [x] App Shortcuts・文言（日英）
- [x] Analytics（`record_housework` / `register_housework`、結果`already_registered` / `memo_limit_exceeded` / `cancelled`）と`doc/analytics_events.md`
- [ ] 実機でSiriから記録・登録できることを確かめる（聞き返し・確認・選択の流れ）
  - 確認への答え方ごとの挙動: 「いいえ」と答える（`false`が返り、「記録しませんでした」・`cancelled`になるか）／ボタンで閉じる／「キャンセル」「やめて」と言う（中断として扱い、`app_intent`を送らないか）
  - 候補が1件で「いいえ」と答えると、続けて新しく登録するかを聞く。2回聞かれて戸惑わないか
- [ ] スパイク → スキーマのADR → iOS 27〜の側
