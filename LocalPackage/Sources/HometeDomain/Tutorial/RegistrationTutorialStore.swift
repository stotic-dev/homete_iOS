//
//  RegistrationTutorialStore.swift
//  LocalPackage
//

import Observation

/// グループ登録の直後に出す、導線を案内するチュートリアルの表示状態を持つ
///
/// 登録の直後に一度だけ出し、最後まで見るか途中で閉じたら二度と出さない。
/// 登録の直後にアプリを終了された場合に備えて「まだ見終わっていない」ことを永続化し、次の起動で出し直す。
@MainActor
@Observable
public final class RegistrationTutorialStore {

    /// 表示中のステップ。表示していないときはnil
    public private(set) var currentStep: RegistrationTutorialStep?

    // MARK: Dependencies

    private let stateClient: RegistrationTutorialStateClient
    private let analyticsClient: AnalyticsClient

    public init(
        currentStep: RegistrationTutorialStep? = nil,
        stateClient: RegistrationTutorialStateClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue
    ) {
        self.currentStep = currentStep
        self.stateClient = stateClient
        self.analyticsClient = analyticsClient
    }

    /// 前回見終わらないまま終了していた場合に、チュートリアルを出し直す
    /// - Parameter hasCohabitant: グループに所属しているかどうか。所属していなければ出さず、
    ///   表示中でも閉じる（ログアウトして、グループに未所属のアカウントでログインし直した場合など）
    public func restoreIfNeeded(hasCohabitant: Bool) async {
        guard hasCohabitant else {
            await dismiss()
            return
        }
        guard currentStep == nil,
              await stateClient.loadIsPending() else { return }

        currentStep = RegistrationTutorialStep.allCases.first
    }

    /// 所属グループが変わったときに、グループ登録の直後であればチュートリアルを始める
    /// - Note: 未所属から所属に変わったときだけを登録の直後とみなす。
    ///         起動時にすでに所属している既存のユーザーには出さない。
    ///         グループを抜けたときは、説明する画面が使えなくなるため表示中でも閉じる
    public func didChangeCohabitant(from oldCohabitantId: String?, to newCohabitantId: String?) async {
        guard newCohabitantId != nil else {
            await dismiss()
            return
        }
        guard oldCohabitantId == nil else { return }

        await start()
    }

    /// チュートリアルを最初のステップから始める
    /// - Note: デバッグメニューからも直接呼ぶ
    public func start() async {
        await stateClient.saveIsPending(true)
        currentStep = RegistrationTutorialStep.allCases.first
    }

    /// 次のステップへ進める。最後のステップなら終える
    /// - Parameter step: 「次へ」を押したときに表示していたステップ。表示中のステップと違えば何もしない
    ///   （ボタンを素早く2回押したときに、ステップを飛ばさないようにする）
    public func next(from step: RegistrationTutorialStep) async {
        guard currentStep == step else { return }

        if let nextStep = step.next {
            currentStep = nextStep
            return
        }
        await finish()
        analyticsClient.log(.registrationTutorial(.completed))
    }

    /// 途中で閉じる
    public func close() async {
        guard let currentStep else { return }

        await finish()
        analyticsClient.log(.registrationTutorial(.skipped(step: currentStep)))
    }

}

private extension RegistrationTutorialStore {

    func finish() async {
        currentStep = nil
        await stateClient.saveIsPending(false)
    }

    /// ユーザーの操作によらずに表示をやめる。見終わったわけではないため、イベントは送らない
    func dismiss() async {
        guard currentStep != nil else { return }

        await finish()
    }

}
