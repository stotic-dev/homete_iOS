#!/usr/bin/env python3
"""LocalPackage・InfraPackageのString Catalogで、英訳が無い文言と使われなくなった文言を一覧にする。

キーは日本語の文言そのものなので、日本語を書き換えると古いキーが残り（stale）、新しいキーには訳が無い状態になる。
どちらかがあれば終了コード1を返す。
"""

import glob
import json
import sys

LANGUAGE = "en"


def main() -> int:
    problems = []
    paths = [
        path
        for package in ("LocalPackage", "InfraPackage")
        for path in glob.glob(f"{package}/Sources/**/Localizable.xcstrings", recursive=True)
    ]
    for path in sorted(paths):
        strings = json.load(open(path, encoding="utf-8"))["strings"]
        for key, entry in strings.items():
            if not key or entry.get("shouldTranslate") is False:
                continue
            if entry.get("extractionState") == "stale":
                problems.append(f"{path}: 使われていない文言 {key!r}")
            elif LANGUAGE not in entry.get("localizations", {}):
                problems.append(f"{path}: 英訳が無い文言 {key!r}")

    for problem in problems:
        print(problem)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
