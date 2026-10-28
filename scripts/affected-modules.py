#!/usr/bin/env python3
"""変更されたファイルから、ビルド・テスト・VRTが必要なモジュールを割り出す。

モジュールの依存はLocalPackage・InfraPackageの `swift package dump-package` から読む。
変更されたターゲットと、それに（推移的に）依存するターゲットを「影響を受けたターゲット」とし、
その範囲だけをビルド・テストする。経緯は doc/adr/0048-verify-only-affected-modules.md。

使い方:
  python3 scripts/affected-modules.py <query> [--base <ref>] [--files <path>...]

  --base   変更の起点。省略時は origin/main。<ref>との分岐点からHEADまでのコミットに加え、
           未コミットの変更と追跡外のファイルも対象にする
  --files  gitを見ずに、渡したパスを変更されたファイルとして扱う（動作確認用）
  --transitive  vrt-tests・vrt-all を、変更から推移的に影響を受けるモジュールで判定する（CI用）。
                省略時は直接変えたモジュールだけ（ローカル用）
  --generated   vrt-tests を、Prefireが生成したテスト（PreviewTests.generated.swift）にあるものだけに絞る

query:
  summary        判定結果を人が読む形で出す
  tests          実行すべきテストターゲット（1行に1つ）
  test-filter    swift test --filter に渡す正規表現。対象が無ければ何も出さない
  build-targets  iOS向けにビルドすべきLocalPackageのターゲット。他の対象に含まれるものは省く
  infra          InfraPackageのビルドが必要なら yes、不要なら no
  app            homete.xcodeproj（アプリ本体）のビルドが必要なら yes、不要なら no
  vrt-tests      流すVRTのテスト名（PreviewTests/test_..._Preview の ... の部分）
  vrt-all        全プレビューを流すべきなら yes。vrt-tests の名前で絞らずに流す
"""
import argparse
import json
import os
import re
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACKAGES = ["LocalPackage", "InfraPackage"]

# 変わるとLocalPackageの全ターゲットに効くもの。SwiftLintはビルド時にプラグインとして走るので、
# 設定が変わればどのターゲットのビルドも結果が変わりうる
ALL_TARGETS_PATTERNS = [
    r"LocalPackage/Package\.(swift|resolved)$",
    r"ProjectTools/",
    r"\.swiftlint\.yml$",
]
INFRA_PATTERNS = [r"InfraPackage/Package\.(swift|resolved)$"]
APP_PATTERNS = [r"homete/", r"hometeNotificationService/", r"homete\.xcodeproj/"]
# VRTの設定・テンプレート。変わったら全プレビューが対象になる
VRT_ALL_PATTERNS = [
    r"hometeVRT\.xcodeproj/",
    r"hometeSnapshotTests/Sources/",
    r"hometeVRTHost/",
    r"\.prefire\.yml$",
    r"snapshotTesting\.xctestplan$",
    r"hometeSnapshotTestsForCI\.xctestplan$",
    # swift-snapshot-testing・Prefireの更新で描画が変わる（#451で約30枚変わった）
    r"(^|/)Package\.resolved$",
]
# 変わったら全プレビューが対象になるターゲット。テストの実行とスナップショットの撮り方を持つ
VRT_ALL_TARGETS = {"HometeSnapshotTestSupport"}
# VRTが描画するモジュール。.prefire.yml の testable_imports と同じ
VRT_MODULES = {
    "HometeUI",
    "AuthFeature",
    "SettingFeature",
    "HomeFeature",
    "CohabitantRegistrationFeature",
    "HouseworkFeature",
    "HouseworkTemplateFeature",
    "ContributionFeature",
    "FrequentHouseworkFeature",
}


def git(*args):
    return subprocess.run(
        ["git", *args], cwd=REPO_ROOT, capture_output=True, text=True, check=True
    ).stdout.splitlines()


def changed_files(base):
    merge_base = git("merge-base", base, "HEAD")[0]
    files = set(git("diff", "--name-only", merge_base, "HEAD"))
    files |= set(git("diff", "--name-only", "HEAD"))
    files |= set(git("ls-files", "--others", "--exclude-standard"))
    return sorted(files)


def load_targets():
    """全パッケージのターゲットを {名前: {package, type, path, deps}} で返す。"""
    targets = {}
    for package in PACKAGES:
        dump = subprocess.run(
            ["swift", "package", "--package-path", os.path.join(REPO_ROOT, package),
             "--disable-sandbox", "dump-package"],
            capture_output=True, text=True, check=True,
        ).stdout
        for target in json.loads(dump)["targets"]:
            if target["type"] not in ("regular", "test"):
                continue
            default_dir = "Tests" if target["type"] == "test" else "Sources"
            path = target.get("path") or f"{default_dir}/{target['name']}"
            deps = set()
            for dep in target["dependencies"]:
                kind, value = next(iter(dep.items()))
                # 別パッケージのプロダクトもターゲットと同じ名前で公開しているので、名前で辿れる
                if kind in ("byName", "target", "product"):
                    deps.add(value[0])
            targets[target["name"]] = {
                "package": package,
                "type": target["type"],
                "path": os.path.normpath(os.path.join(package, path)),
                "deps": deps,
            }
    for target in targets.values():
        # 外部パッケージのプロダクト（Prefireなど）は辿らない
        target["deps"] &= targets.keys()
    return targets


def owner(path, targets):
    """ファイルが属するターゲット。一番深いパスで一致したものを返す。"""
    best = None
    for name, target in targets.items():
        if path.startswith(target["path"] + "/") and (
            best is None or len(target["path"]) > len(targets[best]["path"])
        ):
            best = name
    return best


def matches(path, patterns):
    return any(re.search(p, path) for p in patterns)


def dependents_closure(names, targets):
    affected = set(names)
    while True:
        more = {n for n, t in targets.items() if t["deps"] & affected} - affected
        if not more:
            return affected
        affected |= more


def deps_closure(name, targets):
    seen, stack = set(), [name]
    while stack:
        for dep in targets[stack.pop()]["deps"]:
            if dep not in seen:
                seen.add(dep)
                stack.append(dep)
    return seen


def analyze(files, targets, transitive=False):
    changed = set()
    app = vrt_all = False
    for path in files:
        if matches(path, ALL_TARGETS_PATTERNS):
            changed |= {n for n, t in targets.items() if t["package"] == "LocalPackage"}
        if matches(path, INFRA_PATTERNS):
            changed |= {n for n, t in targets.items() if t["package"] == "InfraPackage"}
        if matches(path, APP_PATTERNS):
            app = True
        if matches(path, VRT_ALL_PATTERNS):
            vrt_all = True
        name = owner(path, targets)
        if name:
            changed.add(name)

    affected = dependents_closure(changed, targets)
    local_regular = {
        n for n in affected
        if targets[n]["package"] == "LocalPackage" and targets[n]["type"] == "regular"
    }
    # 他の対象をビルドすれば一緒にビルドされるものは省く
    covered = set().union(*(deps_closure(n, targets) for n in local_regular)) if local_regular else set()
    vrt_all = vrt_all or bool(changed & VRT_ALL_TARGETS)
    # ローカルのVRTは、直接変えたモジュールのプレビューだけにする。HometeUIやHometeDomainを
    # 変えると全Featureが影響範囲に入るが、全プレビューの確認はCIのVRTに任せる。
    # CIのVRTは推移的に影響を受けるモジュールまで広げる（doc/adr/0063）
    vrt_modules = (affected if transitive else changed) & VRT_MODULES
    vrt_all = vrt_all or vrt_modules == VRT_MODULES
    if vrt_all:
        vrt_modules = VRT_MODULES
    return {
        "changed": sorted(changed),
        "affected": sorted(affected),
        "tests": sorted(n for n in affected if targets[n]["type"] == "test"),
        "build_targets": sorted(local_regular - covered),
        "infra": any(targets[n]["package"] == "InfraPackage" for n in affected),
        "app": app,
        "vrt_modules": sorted(vrt_modules),
        "vrt_all": vrt_all,
    }


def preview_names(module, targets):
    """モジュール内の #Preview から、Prefireが付けるテスト名を組み立てる。

    名前付きの #Preview("名前") はその名前から識別子に使えない文字（空白・括弧など）を除いたもの、
    名前の無いものは「ファイル名_連番」になる。Prefireが対象外にするプレビューも含まれるので、
    実際に流すときは生成されたテストと突き合わせる。
    """
    names = []
    root = os.path.join(REPO_ROOT, targets[module]["path"])
    for dirpath, _, filenames in os.walk(root):
        for filename in sorted(filenames):
            if not filename.endswith(".swift"):
                continue
            with open(os.path.join(dirpath, filename), encoding="utf-8") as f:
                source = f.read()
            unnamed = 0
            for match in re.finditer(r'^#Preview(?:\(\s*"([^"]*)")?', source, re.MULTILINE):
                if match.group(1) is not None:
                    names.append(re.sub(r"\W", "", match.group(1)))
                else:
                    names.append(f"{filename[:-len('.swift')]}_{unnamed}")
                    unnamed += 1
    return names


def generated_tests(path):
    """Prefireが生成したテストのうち、#Preview から作られたものの名前。"""
    with open(path, encoding="utf-8") as f:
        return set(re.findall(r"func test_(\w+)_Preview\(\)", f.read()))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--files", nargs="*")
    parser.add_argument("--transitive", action="store_true")
    parser.add_argument("--generated")
    parser.add_argument("query", choices=[
        "summary", "tests", "test-filter", "build-targets", "infra", "app", "vrt-tests", "vrt-all",
    ])
    args = parser.parse_args()

    targets = load_targets()
    files = args.files if args.files is not None else changed_files(args.base)
    result = analyze(files, targets, transitive=args.transitive)

    if args.query == "summary":
        print(f"変更されたターゲット: {', '.join(result['changed']) or 'なし'}")
        print(f"テスト: {', '.join(result['tests']) or 'なし'}")
        print(f"iOS向けビルド: {', '.join(result['build_targets']) or 'なし'}")
        print(f"InfraPackageのビルド: {'要' if result['infra'] else '不要'}")
        print(f"アプリ本体のビルド: {'要' if result['app'] else '不要'}")
        label = "CIのVRT" if args.transitive else "ローカルVRT"
        modules = "全件" if result["vrt_all"] else ", ".join(result["vrt_modules"]) or "なし"
        print(f"{label}: {modules}")
    elif args.query == "tests":
        print("\n".join(result["tests"]))
    elif args.query == "test-filter":
        if result["tests"]:
            print("|".join(f"^{t}\\." for t in result["tests"]))
    elif args.query == "build-targets":
        print("\n".join(result["build_targets"]))
    elif args.query in ("infra", "app"):
        print("yes" if result[args.query] else "no")
    elif args.query == "vrt-all":
        print("yes" if result["vrt_all"] else "no")
    elif args.query == "vrt-tests":
        available = generated_tests(args.generated) if args.generated else None
        names = [n for m in result["vrt_modules"] for n in preview_names(m, targets)]
        for name in sorted(set(names)):
            if available is None or name in available:
                print(name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
