//
//  BehaviorDriver.swift
//  AgentToolsPackage
//

import HometeIntrospection
import HometeScenarioSupport
import Testing

/// CLIと同じ`AppIntrospector`を通して、シナリオのアプリを操作する
@MainActor
struct BehaviorDriver {

    let backend: FixtureHouseworkBackend
    let introspector: AppIntrospector

    init(_ scenario: Scenario) {
        let environment = scenario.makeEnvironment()
        backend = environment.backend
        introspector = AppIntrospector(session: environment.session)
    }

    var snapshot: AppSnapshot {
        introspector.snapshot()
    }

    /// 操作を実行する。非同期の処理は待たない
    func perform(_ action: String, _ arguments: [String: String] = [:]) throws {
        try introspector.perform(ActionRequest(action: action, arguments: arguments))
    }

    /// 操作を実行し、非同期の処理が終わるまで待つ
    func performAndSettle(_ action: String, _ arguments: [String: String] = [:]) async throws {
        try perform(action, arguments)
        await introspector.settle()
    }

}

/// 「今日の家事」で実行できる操作
func todayActions(hasIncomplete: Bool) -> [ActionDescriptor] {
    guard hasIncomplete else { return [] }
    return [ActionDescriptor(name: "complete", summary: "家事の「完了にする」を押す（完了にするシートを出す）", arguments: ["id"])]
}

/// 完了にするシートで実行できる操作
func completionActions(completed: Bool = false, hasError: Bool = false) -> [ActionDescriptor] {
    var actions: [ActionDescriptor] = []
    if !completed {
        actions += [
            ActionDescriptor(name: "selectEffort", summary: "頑張り度を選ぶ（normal・hard・veryHard）", arguments: ["effort"]),
            ActionDescriptor(name: "toggleMember", summary: "担当者の選択を切り替える", arguments: ["userId"]),
            ActionDescriptor(name: "save", summary: "完了ボタンを押す"),
            ActionDescriptor(name: "close", summary: "閉じるボタンを押す"),
        ]
    }
    actions.append(ActionDescriptor(name: "dismiss", summary: "シートを下へスワイプして閉じる"))
    if completed {
        actions.append(ActionDescriptor(name: "finishPraise", summary: "ほめる演出を見せ終える"))
    }
    if hasError {
        actions.append(ActionDescriptor(name: "dismissError", summary: "エラーのアラートを閉じる"))
    }
    return actions
}
