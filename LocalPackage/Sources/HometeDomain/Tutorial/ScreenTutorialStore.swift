//
//  ScreenTutorialStore.swift
//  LocalPackage
//

import Observation

/// 画面を初めて開いたときに出す、その画面の使い方を説明するチュートリアルの表示状態を持つ
///
/// 画面ごとに一度だけ出し、最後まで見るか途中で閉じたら二度と出さない。
/// 途中でアプリを終了されたときは見たことにせず、次に画面を開いたときに出し直す。
/// 画面を開いている間だけ使うため、画面ごとに作って画面を閉じたら破棄してよい。
@MainActor
@Observable
public final class ScreenTutorialStore<Step: ScreenTutorialStep> {

    /// 表示中のステップ。表示していないときはnil
    public private(set) var currentStep: Step?

    // MARK: Dependencies

    private let stateClient: ScreenTutorialStateClient
    private let analyticsClient: AnalyticsClient

    public init(
        currentStep: Step? = nil,
        stateClient: ScreenTutorialStateClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue
    ) {
        self.currentStep = currentStep
        self.stateClient = stateClient
        self.analyticsClient = analyticsClient
    }

    /// まだ見ていなければ、最初のステップから出す
    public func startIfNeeded() async {
        guard currentStep == nil,
              await !stateClient.loadHasSeen(Step.screen) else { return }

        currentStep = Step.allCases.first
    }

    /// 次のステップへ進める。最後のステップなら終える
    /// - Parameter step: 「次へ」を押したときに表示していたステップ。表示中のステップと違えば何もしない
    ///   （ボタンを素早く2回押したときに、ステップを飛ばさないようにする）
    public func next(from step: Step) async {
        guard currentStep == step else { return }

        if let nextStep = step.next {
            currentStep = nextStep
            return
        }
        await finish()
        analyticsClient.log(.screenTutorial(.completed(screen: Step.screen)))
    }

    /// 前のステップへ戻す。最初のステップなら何もしない
    /// - Parameter step: 「前へ」を押したときに表示していたステップ。表示中のステップと違えば何もしない
    ///   （ボタンを素早く2回押したときに、ステップを飛ばさないようにする）
    public func back(from step: Step) {
        guard currentStep == step,
              let previousStep = step.previous else { return }

        currentStep = previousStep
    }

    /// 途中で閉じる
    public func close() async {
        guard let currentStep else { return }

        await finish()
        analyticsClient.log(.screenTutorial(.skipped(screen: Step.screen, step: currentStep.rawValue)))
    }

}

private extension ScreenTutorialStore {

    func finish() async {
        currentStep = nil
        await stateClient.saveHasSeen(Step.screen, true)
    }

}
