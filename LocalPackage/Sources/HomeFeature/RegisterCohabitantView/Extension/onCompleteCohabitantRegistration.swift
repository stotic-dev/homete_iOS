import SwiftUI

extension EnvironmentValues {
    
    /// パートナーの登録完了通知
    @Entry var onCompleteCohabitantRegistration: (_ cohabitantId: String) -> Void = { _ in }
}

extension View {
    
    /// パートナーの登録完了通知
    func onCompleteCohabitantRegistration(handler: @escaping (_ cohabitantId: String) -> Void) -> some View {
        
        self.environment(\.onCompleteCohabitantRegistration, handler)
    }
}
