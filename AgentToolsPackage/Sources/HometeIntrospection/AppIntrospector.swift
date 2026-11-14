//
//  AppIntrospector.swift
//  AgentToolsPackage
//

import HometeAppCore
import HometeDomain

/// 今の画面・状態・実行できる操作をJSONにし、JSONの操作を一番上の画面（と、それを出している親）のViewModelへ渡す
///
/// 業務ロジックや画面の分岐はここに書かず、ViewModelに任せる。iOSの画面で押せない・出ていない操作は並べない。
@MainActor
public final class AppIntrospector {

    public let session: AgentSession

    public init(session: AgentSession) {
        self.session = session
    }

    public func snapshot() -> AppSnapshot {
        AppSnapshot(
            currentScreen: currentScreen,
            todayHousework: TodayHouseworkSnapshot(session.today.summary),
            houseworkComplete: session.today.completion.map(HouseworkCompleteSnapshot.init),
            availableActions: availableActions().map(\.descriptor)
        )
    }

    /// 操作を実行する。非同期の処理の完了は待たないので、結果を見るときは`settle()`を待つ
    public func perform(_ request: ActionRequest) throws(IntrospectionError) {
        guard let action = availableActions().first(where: { $0.descriptor.name == request.action }) else {
            if Self.allActionNames.contains(request.action) {
                throw IntrospectionError(
                    code: .actionNotAvailable,
                    message: "\(request.action) は今の画面（\(currentScreen.rawValue)）では実行できません"
                )
            }
            throw IntrospectionError(code: .unknownAction, message: "\(request.action) という操作はありません")
        }
        let expected = Set(action.descriptor.arguments)
        let actual = Set(request.arguments.keys)
        guard expected == actual else {
            throw IntrospectionError(
                code: .invalidArguments,
                message: "\(request.action) の引数は \(action.descriptor.arguments) です（受け取った引数: \(actual.sorted())）"
            )
        }
        try action.run(request.arguments)
    }

    /// ViewModelが始めた非同期の処理がすべて終わるまで待つ
    public func settle() async {
        await session.settle()
    }

}

private extension AppIntrospector {

    struct AvailableAction {

        let descriptor: ActionDescriptor
        let run: @MainActor ([String: String]) throws(IntrospectionError) -> Void

        init(
            _ name: String,
            arguments: [String] = [],
            summary: String,
            run: @escaping @MainActor ([String: String]) throws(IntrospectionError) -> Void
        ) {
            descriptor = ActionDescriptor(name: name, summary: summary, arguments: arguments)
            self.run = run
        }

    }

    static let allActionNames: Set<String> = [
        "complete", "selectEffort", "toggleMember", "save", "close", "dismiss", "finishPraise", "dismissError",
    ]

    static let efforts: [String: HouseworkEffort] = ["normal": .normal, "hard": .hard, "veryHard": .veryHard]

    var currentScreen: ScreenName {
        session.today.completion == nil ? .todayHousework : .houseworkComplete
    }

    func availableActions() -> [AvailableAction] {
        let today = session.today
        guard let completion = today.completion else {
            return todayActions(today)
        }
        return completionActions(completion, today: today)
    }

    func todayActions(_ today: TodayHouseworkViewModel) -> [AvailableAction] {
        // 「完了にする」は、今日の未完了の家事があるときだけ押せる
        guard !today.summary.incompleteItems.isEmpty else { return [] }
        return [
            AvailableAction("complete", arguments: ["id"], summary: "家事の「完了にする」を押す（完了にするシートを出す）") { arguments in
                today.send(.completeTapped(itemId: arguments["id", default: ""]))
            },
        ]
    }

    func completionActions(
        _ completion: HouseworkCompleteViewModel,
        today: TodayHouseworkViewModel
    ) -> [AvailableAction] {
        let state = completion.state
        var actions: [AvailableAction] = []
        if state.isEditable {
            actions += [
                AvailableAction(
                    "selectEffort",
                    arguments: ["effort"],
                    summary: "頑張り度を選ぶ（normal・hard・veryHard）"
                ) { arguments throws(IntrospectionError) in
                    guard let effort = Self.efforts[arguments["effort", default: ""]] else {
                        throw IntrospectionError(
                            code: .invalidArguments,
                            message: "effort は normal・hard・veryHard のどれかです"
                        )
                    }
                    completion.send(.effortSelected(effort))
                },
                AvailableAction("toggleMember", arguments: ["userId"], summary: "担当者の選択を切り替える") { arguments in
                    completion.send(.memberToggled(userId: arguments["userId", default: ""]))
                },
            ]
        }
        if state.canComplete {
            actions.append(AvailableAction("save", summary: "完了ボタンを押す") { _ in
                completion.send(.completeTapped)
            })
        }
        if state.canClose {
            actions.append(AvailableAction("close", summary: "閉じるボタンを押す") { _ in
                completion.send(.closeTapped)
            })
        }
        if state.canDismiss {
            actions.append(AvailableAction("dismiss", summary: "シートを下へスワイプして閉じる") { _ in
                today.send(.completionDismissed)
            })
        }
        if state.isPraising {
            actions.append(AvailableAction("finishPraise", summary: "ほめる演出を見せ終える") { _ in
                completion.send(.praiseFinished)
            })
        }
        if state.error != nil {
            actions.append(AvailableAction("dismissError", summary: "エラーのアラートを閉じる") { _ in
                completion.send(.errorDismissed)
            })
        }
        return actions
    }

}
