//
//  LoginContext+Environment.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

import HometeDomain
import SwiftUI

public extension EnvironmentValues {

    @Entry var loginContext = LoginContext(account: .init(id: "", userName: "", fcmToken: nil, cohabitantId: nil))

}

#if DEBUG

public extension View {

    /// ログイン中のアカウントをプレビュー用に固定する
    ///
    /// 実施者が自分かどうかで表示が変わるViewでは、`\.loginContext`の既定値（空のアカウントID）のままだと
    /// 意図した分岐を描画できない。`ownUserId`にはそのプレビューで「自分」として扱いたいIDを渡す。
    ///
    /// - Note: この手のヘルパーはView実装ファイル側に`private`で置かないこと。
    ///   Prefireは`#Preview`の中身を`PreviewTests.generated.swift`へ展開するため、
    ///   `private`/`fileprivate`のシンボルはVRTのビルドから参照できずコンパイルエラーになる。
    func setupLoginContextForPreview(ownUserId: String = "ownUserId") -> some View {
        environment(
            \.loginContext,
            .init(account: .init(
                id: ownUserId,
                userName: "own",
                fcmToken: nil,
                cohabitantId: "cohabitantId"
            ))
        )
    }

}

#endif
