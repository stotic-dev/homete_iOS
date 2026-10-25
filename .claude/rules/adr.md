# ADR（Architecture Decision Record）ルール

## ADRを記載するタイミング

以下のような技術選定・アーキテクチャに関わる判断を行った場合は、必ず ADR を作成する。

- 採用するライブラリ・フレームワークの選定
- アーキテクチャパターンの採用・変更（例: マルチモジュール化、状態管理の方式）
- 複数の実装方針を比較検討した上で選択した場合
- 既存の技術的負債の解消方針を決定した場合

## ファイルの配置

- 保存先: `doc/adr/`
- ファイル名: `NNNN-<kebab-case-title>.md`（例: `0001-spm-multimodule-structure.md`）
- 連番は既存ファイルの最大番号 +1 とする。0054 までは [homete_backend](https://github.com/stotic-dev/homete_backend) と共通の番号空間で、backend へ移した ADR（0007・0008・0014 の一部・0015・0028）の番号は欠番のまま再利用しない。0055 以降は両リポジトリの `docs/adr/`・`doc/adr/` の最大番号 +1 を取り、番号が重ならないようにする

## フォーマット

テンプレートは `doc/adr/template.md` を使用する。

## 他ドキュメントからの参照

技術詳細ドキュメント（例: `doc/multimodules_structure.md`）からは、対応する ADR へのリンクを冒頭に記載する。

```markdown
> この構成を採用した背景・意思決定の経緯は [ADR-NNNN](adr/NNNN-title.md) を参照。
```
