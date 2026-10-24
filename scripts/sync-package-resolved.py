#!/usr/bin/env python3
"""アプリ・VRTのxcodeprojのPackage.resolvedを、参照しているローカルパッケージの解決結果にそろえる。

xcodeprojでビルドすると、使われるのはルート（xcodeproj）のPackage.resolvedだけで、
InfraPackage・LocalPackage側のPackage.resolvedは読まれない。dependabotはパッケージ側しか更新しないので、
そのままではリリースされるアプリのライブラリが古い版に固定されたままになる。

xcodeproj側にあるパッケージの版・revisionだけをパッケージ側の値で上書きする。
パッケージの追加・削除はXcodeで解決し直す必要があるため扱わない。

使い方:
  scripts/sync-package-resolved.py          書き換える
  scripts/sync-package-resolved.py --check  ずれがあれば一覧を出して終了コード1を返す（書き換えない）
  --root <dir>  リポジトリのルート（既定はカレントディレクトリ）
"""

import argparse
import json
import os
import sys

# (ルートのPackage.resolved, 版の取り元にするパッケージのPackage.resolved)
# InfraPackageはLocalPackageに依存しているので、アプリが使うパッケージを全部含む
TARGETS = [
    ("homete.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved", "InfraPackage/Package.resolved"),
    ("hometeVRT.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved", "LocalPackage/Package.resolved"),
]


def load(path):
    with open(path, encoding="utf-8") as file:
        return json.load(file)


def dump(path, data):
    # Xcode・SwiftPMが書く書式（2スペースのインデント、"key" : value）に合わせる
    with open(path, "w", encoding="utf-8") as file:
        file.write(json.dumps(data, indent=2, separators=(",", " : "), ensure_ascii=False) + "\n")


def sync(root_path, source_path):
    """ルート側をそろえた内容と、ずれていたパッケージの一覧を返す。"""
    root = load(root_path)
    source_states = {pin["identity"]: pin["state"] for pin in load(source_path)["pins"]}
    changes = []
    for pin in root["pins"]:
        source_state = source_states.get(pin["identity"])
        if source_state is None or source_state == pin["state"]:
            continue
        changes.append((pin["identity"], describe(pin["state"]), describe(source_state)))
        pin["state"] = source_state
    return root, changes


def describe(state):
    return state.get("version") or state.get("branch") or state["revision"][:8]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--root", default=".")
    args = parser.parse_args()

    drifted = False
    for root_path, source_path in TARGETS:
        root_path = os.path.join(args.root, root_path)
        source_path = os.path.join(args.root, source_path)
        synced, changes = sync(root_path, source_path)
        if not changes:
            continue
        drifted = True
        for identity, current, expected in changes:
            print(f"{root_path}: {identity} {current} -> {expected}（{source_path}）")
        if not args.check:
            dump(root_path, synced)

    if args.check and drifted:
        print("scripts/sync-package-resolved.py を実行してそろえてください。")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
