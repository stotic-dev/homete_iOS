#!/usr/bin/env python3
"""SwiftPMのビルドディレクトリロック（<build-path>/.lock）の保持状況を調べる。

背景: Claude Codeのサンドボックス下では ps / pgrep / sysctl kern.proc がすべて
禁止されており、「どのプロセスがロックを握っているか」をプロセス一覧から突き止め
られない。一方 SwiftPM は .build/.lock に自身のPIDを書き込んだうえで flock(2) で
排他するため、このファイルだけを見れば「ロックが握られているか」「握っているのは
誰か」がプロセス一覧なしで分かる。

ロックが握られている間、後続の swift コマンドは何も出力しないまま待ち続ける
（"Another instance of SwiftPM ..." すら出ないことがある）ため、ハングと区別が
つかない。その判別材料を出すのがこのスクリプトの役割。

出力は1行:
    held <pid>  ロックは保持されている（<pid>は.lockに記録された保持者。不明なら-）
    free        ロックは保持されていない
    absent      .lockが存在しない（= まだ一度もビルドしていない）
    unknown <理由>
              判定できなかった

終了コード: held=0 / free・absent=1 / unknown・引数エラー=2

使い方: scripts/swiftpm-build-lock.py <ビルドディレクトリ（.build）の絶対パス>
"""

import fcntl
import os
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <build directory path>", file=sys.stderr)
        return 2

    lock_path = os.path.join(sys.argv[1], ".lock")
    if not os.path.exists(lock_path):
        print("absent")
        return 1

    # PIDの読み出しはロック判定と独立に行う。ロックが解放済みでも中身は残るため、
    # 「記録されたPID」は保持者の手掛かりでしかなく、単独では信用しない。
    try:
        with open(lock_path, "r") as f:
            recorded = f.read().strip()
    except OSError:
        recorded = ""
    pid = recorded if recorded.isdigit() else "-"

    try:
        fd = os.open(lock_path, os.O_RDWR)
    except OSError as e:
        print(f"unknown {type(e).__name__}")
        return 2

    try:
        # 非ブロッキングで取れれば誰も握っていない。取れた分はその場で解放する。
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print(f"held {pid}")
        return 0
    except OSError as e:
        print(f"unknown {type(e).__name__}")
        return 2
    else:
        fcntl.flock(fd, fcntl.LOCK_UN)
        print("free")
        return 1
    finally:
        os.close(fd)


if __name__ == "__main__":
    sys.exit(main())
