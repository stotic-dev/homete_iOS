import SwiftUI

extension EnvironmentValues {

    /// パートナーの登録完了通知
    /// - Note: 自分のアカウントへ同居人IDを保存し、失敗した場合はthrowする。
    ///         呼び出し側は完了を待ってから他デバイスへ完了を伝えること
    @Entry var onCompleteCohabitantRegistration: (_ cohabitantId: String) async throws -> Void = { _ in }

}

extension View {

    /// パートナーの登録完了通知
    func onCompleteCohabitantRegistration(
        handler: @escaping (_ cohabitantId: String) async throws -> Void
    ) -> some View {
        environment(\.onCompleteCohabitantRegistration, handler)
    }

}
