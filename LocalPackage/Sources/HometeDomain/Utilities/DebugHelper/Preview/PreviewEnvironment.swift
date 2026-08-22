//
//  PreviewEnvironment.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import SwiftUI

#if DEBUG

public extension View {

    func setupEnvironmentForPreview() -> some View {
        var calendar = Calendar.japanese
        calendar.timeZone = .tokyo
        return environment(\.locale, .jp)
            .environment(\.timeZone, .tokyo)
            .environment(\.calendar, calendar)
    }

    /// 保存期間の判定に関わる環境値をプレビュー用に固定する
    ///
    /// `\.now`の既定値は実行時の現在日時のため、固定の日付を前提にしたプレビューは
    /// 時間が経つだけで「保存期間外」表示へ勝手に切り替わり、VRTの差分になってしまう。
    /// 保存期間の判定に関わるViewのプレビューでは必ず現在日時とプランを固定すること。
    ///
    /// - Note: この手のヘルパーはView実装ファイル側に`private extension View`で置かないこと。
    ///   Prefireは`#Preview`の中身を`PreviewTests.generated.swift`へ展開するため、
    ///   `private`/`fileprivate`のシンボルはVRTのビルドから参照できずコンパイルエラーになる。
    func setupStorageEnvironmentForPreview(
        now: Date,
        storagePolicy: HouseworkStoragePolicy = .premium
    ) -> some View {
        environment(\.now, now)
            .environment(\.houseworkStoragePolicy, storagePolicy)
    }

}

#endif
