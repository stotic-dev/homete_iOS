//
//  OpenHouseworkCompleteIntent.swift
//  LocalPackage
//

import AppIntents
import HometeDomain

/// アプリを開いて、家事の完了を記録するシートを出す
///
/// 頑張り度や担当者を選んで記録したいときに使う。ショートカットAppと、OSの提案から使う。
struct OpenHouseworkCompleteIntent: AppIntent {

    static let title: LocalizedStringResource = "家事の完了を記録する"
    static let description = IntentDescription("アプリを開いて、家事の完了を記録する画面を出します")
    static let openAppWhenRun = true

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$housework)の完了を記録する")
    }

    @Parameter(title: "家事", requestValueDialog: "どの家事を記録しますか？")
    var housework: HouseworkTitleEntity

    @Dependency var environment: AppIntentEnvironment
    @Dependency var pendingRouteStore: PendingRouteStore

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        // 家事の読み込みを待ってから開くため、開く画面を退避して家事ボードに任せる
        pendingRouteStore.store(.houseworkComplete(houseworkTitle: housework.id))
        environment.analyticsClient.log(.appIntent(.openHouseworkComplete, result: .success))
        return .result()
    }

}
