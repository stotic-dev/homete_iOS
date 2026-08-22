#!/usr/bin/env python3
"""Prefireのスナップショットテスト生成で壊れる`#Preview`を静的に検出する。

背景:
    Prefireは`#Preview`の中身を`hometeSnapshotTests/PreviewTests.generated.swift`へ
    そのまま展開し、対象モジュールを`@testable import`してビルドする。
    そのため`#Preview`が参照するシンボルは最低でもinternalである必要があり、
    `private`/`fileprivate`だと「is inaccessible due to 'fileprivate' protection level」で
    VRTのビルドだけが落ちる。ローカルの`make test-packages`はLocalPackage単体の
    ビルドしか行わない（生成コードはビルド対象外）ため、この種の誤りは
    Xcode Cloudに投げるまで気付けない。それを手前で潰すのがこのスクリプト。

検出するもの:
    1. `#Preview`ブロックから参照されている、同一ファイル内のprivate/fileprivateシンボル
    2. `#Preview`を持つモジュールが`.prefire.yml`のimports/testable_importsに未登録

使い方:
    make check-previews          # 全体をチェック
    scripts/check-prefire-previews.py [ファイル...]
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_ROOTS = ["LocalPackage/Sources", "homete/Views"]

# ファイルスコープのprivate/fileprivate宣言。型の内部に書かれたprivateメンバーは
# そもそも`#Preview`から名前で参照できず誤検知になるだけなので、対象にしない。
TOP_LEVEL_DECL = re.compile(
    r"^(?:private|fileprivate)\s+"
    r"(?:final\s+|static\s+|@MainActor\s+)*"
    r"(?:struct|enum|class|actor|func|var|let|typealias)\s+"
    r"([A-Za-z_][A-Za-z0-9_]*)"
)
# `private extension View { ... }` のメンバー。これが今回踏んだパターン。
PRIVATE_EXTENSION = re.compile(r"^(?:private|fileprivate)\s+extension\s+")
# インデント4スペースちょうど = extension直下のメンバー。関数本体のローカル変数
# （8スペース以上）まで拾うと `let frame = ...` のような名前で誤検知する。
EXTENSION_MEMBER = re.compile(
    r"^ {4}(?! )(?:(?:public|internal|private|fileprivate)\s+)?"
    r"(?:static\s+|@ViewBuilder\s+|@MainActor\s+)*"
    r"(?:func|var|let)\s+([A-Za-z_][A-Za-z0-9_]*)"
)


def find_block_end(lines: list[str], start: int) -> int:
    """`start`行から始まるブレースブロックの終了行（含む）を返す。"""
    depth = 0
    opened = False
    for index in range(start, len(lines)):
        # 文字列リテラル中の波括弧は数えたくないので雑に除去する
        line = re.sub(r'"(?:[^"\\]|\\.)*"', '""', lines[index])
        depth += line.count("{") - line.count("}")
        if "{" in line:
            opened = True
        if opened and depth <= 0:
            return index
    return len(lines) - 1


def collect_inaccessible_symbols(lines: list[str]) -> dict[str, int]:
    """`#Preview`から参照できないシンボル名 -> 宣言行番号(1始まり)。"""
    symbols: dict[str, int] = {}
    index = 0
    while index < len(lines):
        line = lines[index]
        if PRIVATE_EXTENSION.match(line):
            end = find_block_end(lines, index)
            for inner in range(index + 1, end):
                member = EXTENSION_MEMBER.match(lines[inner])
                if member:
                    symbols.setdefault(member.group(1), inner + 1)
            index = end + 1
            continue
        decl = TOP_LEVEL_DECL.match(line)
        if decl:
            symbols.setdefault(decl.group(1), index + 1)
        index += 1
    return symbols


def collect_preview_blocks(lines: list[str]) -> list[tuple[int, int]]:
    blocks: list[tuple[int, int]] = []
    index = 0
    while index < len(lines):
        if lines[index].lstrip().startswith("#Preview"):
            end = find_block_end(lines, index)
            blocks.append((index, end))
            index = end + 1
            continue
        index += 1
    return blocks


def module_name(path: Path) -> str | None:
    relative = path.relative_to(REPO_ROOT).as_posix()
    if not relative.startswith("LocalPackage/Sources/"):
        return None
    parts = relative.split("/")[2:]
    if parts[0] == "Features":
        parts = parts[1:]
    return parts[0] if len(parts) > 1 else None


def prefire_modules() -> set[str]:
    config = (REPO_ROOT / ".prefire.yml").read_text(encoding="utf-8")
    return set(re.findall(r"^\s*-\s*([A-Za-z_][A-Za-z0-9_]*)\s*$", config, re.MULTILINE))


def check_file(path: Path, modules: set[str]) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    blocks = collect_preview_blocks(lines)
    if not blocks:
        return []

    relative = path.relative_to(REPO_ROOT).as_posix()
    problems: list[str] = []

    module = module_name(path)
    if module and module not in modules:
        problems.append(
            f"{relative}: モジュール '{module}' が .prefire.yml の imports / testable_imports に"
            " 未登録のため、生成されるスナップショットテストからViewを参照できません。"
        )

    symbols = collect_inaccessible_symbols(lines)
    if not symbols:
        return problems

    for name, declared_line in sorted(symbols.items(), key=lambda item: item[1]):
        # 引数ラベル・辞書キーとしての一致は宣言の参照ではないため除外する
        pattern = re.compile(rf"\b{re.escape(name)}\b(?!\s*:)")
        for start, end in blocks:
            for offset in range(start, end + 1):
                if pattern.search(lines[offset]):
                    problems.append(
                        f"{relative}:{offset + 1}: #Preview が private/fileprivate な "
                        f"'{name}'（{relative}:{declared_line} で宣言）を参照しています。"
                        " internal 以上に上げるか、共通のプレビューヘルパーへ移動してください。"
                    )
                    break
            else:
                continue
            break
    return problems


def target_files(arguments: list[str]) -> list[Path]:
    if arguments:
        return [Path(argument).resolve() for argument in arguments if argument.endswith(".swift")]
    result = subprocess.run(
        ["git", "ls-files", "--", *[f"{root}/**/*.swift" for root in SOURCE_ROOTS]],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return [REPO_ROOT / line for line in result.stdout.splitlines() if line]


def main() -> int:
    modules = prefire_modules()
    problems: list[str] = []
    for path in target_files(sys.argv[1:]):
        if path.exists():
            problems.extend(check_file(path, modules))

    if not problems:
        return 0

    print("❌ Prefire（VRT）のビルドが壊れる #Preview を検出しました:", file=sys.stderr)
    for problem in problems:
        print(f"  - {problem}", file=sys.stderr)
    print(
        "\n詳細: .claude/rules/prefire-preview.md",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
