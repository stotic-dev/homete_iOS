//
//  AppSnapshot.swift
//  AgentToolsPackage
//

import HometeAppCore
import HometeDomain

public enum ScreenName: String, Codable, Equatable, Sendable {

    /// ダッシュボードの「今日の家事」
    case todayHousework
    /// 家事を完了にするハーフモーダル
    case houseworkComplete

}

/// 今の画面・状態・実行できる操作
public struct AppSnapshot: Codable, Equatable, Sendable {

    /// 一番上に出ている画面
    public var currentScreen: ScreenName
    public var todayHousework: TodayHouseworkSnapshot
    /// 完了にするシートを出していなければ`nil`
    public var houseworkComplete: HouseworkCompleteSnapshot?
    /// 今の画面で実行できる操作
    public var availableActions: [ActionDescriptor]

    public init(
        currentScreen: ScreenName,
        todayHousework: TodayHouseworkSnapshot,
        houseworkComplete: HouseworkCompleteSnapshot?,
        availableActions: [ActionDescriptor]
    ) {
        self.currentScreen = currentScreen
        self.todayHousework = todayHousework
        self.houseworkComplete = houseworkComplete
        self.availableActions = availableActions
    }

}

public struct TodayHouseworkSnapshot: Codable, Equatable, Sendable {

    /// 今日の未完了の家事（表示順）
    public var incomplete: [HouseworkSnapshot]
    /// 今日の家事のうち、完了した数
    public var completedCount: Int
    /// 今日の家事の数（「やらない」にしたものを含む）
    public var totalCount: Int

    public init(incomplete: [HouseworkSnapshot], completedCount: Int, totalCount: Int) {
        self.incomplete = incomplete
        self.completedCount = completedCount
        self.totalCount = totalCount
    }

    init(_ summary: TodayHouseworkSummary) {
        self.init(
            incomplete: summary.incompleteItems.map(HouseworkSnapshot.init),
            completedCount: summary.allItems.count { $0.state == .completed },
            totalCount: summary.allItems.count
        )
    }

}

public struct HouseworkSnapshot: Codable, Equatable, Sendable {

    public var id: String
    public var title: String
    public var point: Int

    public init(id: String, title: String, point: Int) {
        self.id = id
        self.title = title
        self.point = point
    }

    init(_ item: HouseworkBoardItem) {
        self.init(id: item.id, title: item.title, point: item.originalItem.point)
    }

}

public struct HouseworkCompleteSnapshot: Codable, Equatable, Sendable {

    public struct Executor: Codable, Equatable, Sendable {

        public var userId: String
        public var percentage: Int

        public init(userId: String, percentage: Int) {
            self.userId = userId
            self.percentage = percentage
        }

    }

    public var houseworkId: String
    public var title: String
    /// `HouseworkEffort`の名前（`normal`・`hard`・`veryHard`）
    public var effort: String
    /// 担当者として選べるメンバーのユーザーID（メンバー一覧の並び順）
    public var selectableMemberIds: [String]
    /// 選んでいる担当者と、ポイントの割合
    public var executors: [Executor]
    /// 頑張り度を反映した、担当者に配るポイントの合計
    public var totalPoint: Int
    public var isCompleting: Bool
    /// 完了にできたときに配ったポイントの合計。入るとほめる演出が出ている
    public var completedPoint: Int?
    /// `DomainError`の名前
    public var error: String?

    public init(
        houseworkId: String,
        title: String,
        effort: String,
        selectableMemberIds: [String],
        executors: [Executor],
        totalPoint: Int,
        isCompleting: Bool = false,
        completedPoint: Int? = nil,
        error: String? = nil
    ) {
        self.houseworkId = houseworkId
        self.title = title
        self.effort = effort
        self.selectableMemberIds = selectableMemberIds
        self.executors = executors
        self.totalPoint = totalPoint
        self.isCompleting = isCompleting
        self.completedPoint = completedPoint
        self.error = error
    }

    @MainActor
    init(_ viewModel: HouseworkCompleteViewModel) {
        let state = viewModel.state
        self.init(
            houseworkId: viewModel.item.id,
            title: viewModel.item.title,
            effort: SnapshotName.effort(state.allocation.effort),
            selectableMemberIds: viewModel.selectableMembers.map(\.id),
            executors: state.allocation.entries.map { .init(userId: $0.userId, percentage: $0.percentage) },
            totalPoint: state.allocation.totalPoint,
            isCompleting: state.isCompleting,
            completedPoint: state.completedPoint,
            error: state.error.map(SnapshotName.error)
        )
    }

}

public struct ActionDescriptor: Codable, Equatable, Sendable {

    /// `ActionRequest.action`に渡す名前
    public var name: String
    /// 必要な引数の名前。値はすべて文字列で渡す
    public var arguments: [String]
    public var summary: String

    public init(name: String, summary: String, arguments: [String] = []) {
        self.name = name
        self.arguments = arguments
        self.summary = summary
    }

}

/// スナップショット・操作の引数で使う、値の名前
///
/// `CustomStringConvertible`の有無で出力が変わらないよう、名前は明示的に決める
enum SnapshotName {

    static let efforts: [(name: String, effort: HouseworkEffort)] = [
        ("normal", .normal),
        ("hard", .hard),
        ("veryHard", .veryHard),
    ]

    static func effort(_ effort: HouseworkEffort) -> String {
        efforts.first { $0.effort == effort }?.name ?? "unknown"
    }

    static func effort(named name: String) -> HouseworkEffort? {
        efforts.first { $0.name == name }?.effort
    }

    static func error(_ error: DomainError) -> String {
        switch error {
        case .failAuth:
            "failAuth"

        case .noNetwork:
            "noNetwork"

        case .accountNotFound:
            "accountNotFound"

        case .other:
            "other"
        }
    }

}
