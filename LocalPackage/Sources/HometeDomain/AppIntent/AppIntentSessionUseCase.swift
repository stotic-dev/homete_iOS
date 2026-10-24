//
//  AppIntentSessionUseCase.swift
//  LocalPackage
//

import Foundation

/// アプリを開かずに実行するApp Intentで、実行する人・グループと、判断に使うデータをサーバーから1回だけ取得する
///
/// 画面と違ってリスナーを張らない。Intentは数秒で終わるため、購読の後片付けが要らない取得だけで組む
/// （[ADR-0044](doc/adr/0044-app-intents-headless-usecase-and-title-keyed-entity.md)）。
public struct AppIntentSessionUseCase: Sendable {

    private let accountAuthClient: AccountAuthClient
    private let accountInfoClient: AccountInfoClient
    private let cohabitantClient: CohabitantClient
    private let houseworkClient: HouseworkClient
    private let houseworkTemplateClient: HouseworkTemplateClient
    private let frequentHouseworkClient: FrequentHouseworkClient
    private let remoteConfigClient: RemoteConfigClient
    private let currentAppVersion: String

    public init(
        accountAuthClient: AccountAuthClient,
        accountInfoClient: AccountInfoClient,
        cohabitantClient: CohabitantClient,
        houseworkClient: HouseworkClient,
        houseworkTemplateClient: HouseworkTemplateClient,
        frequentHouseworkClient: FrequentHouseworkClient,
        remoteConfigClient: RemoteConfigClient,
        currentAppVersion: String
    ) {
        self.accountAuthClient = accountAuthClient
        self.accountInfoClient = accountInfoClient
        self.cohabitantClient = cohabitantClient
        self.houseworkClient = houseworkClient
        self.houseworkTemplateClient = houseworkTemplateClient
        self.frequentHouseworkClient = frequentHouseworkClient
        self.remoteConfigClient = remoteConfigClient
        self.currentAppVersion = currentAppVersion
    }

    /// ログイン中のアカウントと所属グループを取得する
    /// - Parameter requiresLatestVersion: 書き込むIntentでは`true`を渡し、強制アップデートが必要なバージョンなら実行させない。
    ///   最低バージョンは、最後に反映したRemote Configの値で判定する（Intentのためにサーバーへは問い合わせない）
    /// - Throws: 未ログインは`AppIntentFailure.notLoggedIn`、未所属は`.noCohabitant`、
    ///   アップデートが必要なら`.updateRequired`。通信の失敗はそのまま投げる
    public func resolve(requiresLatestVersion: Bool) async throws -> AppIntentSession {
        if requiresLatestVersion, ForceUpdatePolicy.isRequired(
            currentVersion: currentAppVersion,
            minimumRequiredVersion: remoteConfigClient.string(.minimumRequiredVersion)
        ) {
            throw AppIntentFailure.updateRequired
        }
        guard let auth = accountAuthClient.currentAuth(),
              let account = try await accountInfoClient.fetch(auth.id) else {
            throw AppIntentFailure.notLoggedIn
        }
        guard let cohabitantId = account.cohabitantId else {
            throw AppIntentFailure.noCohabitant
        }
        return .init(account: account, cohabitantId: cohabitantId)
    }

    /// 指定した日の家事を取得する
    /// - Parameter days: 取得する日（その日の0時）。連続した日を渡す
    public func fetchHousework(
        session: AppIntentSession,
        days: [Date],
        calendar: Calendar
    ) async throws -> StoredAllHouseworkList {
        guard let from = days.min(), let to = days.max() else { return .init(value: []) }

        let items = try await houseworkClient.fetchItems(session.cohabitantId, from, to)
        return .makeMultiDateList(
            items: items,
            anchorDate: to,
            offsetDays: days.count - 1,
            calendar: calendar
        )
    }

    /// グループで使っているテンプレートを取得する
    ///
    /// 家事ボードと同じく、未登録のテンプレートの家事も今日の家事として扱うために使う。
    /// 毎月の家事の取得に失敗しても、毎週の家事だけで続ける（`HouseworkTemplateListStore.loadMonthlyItems`と同じ方針）。
    public func fetchTemplateContext(session: AppIntentSession) async throws -> HouseworkTemplateContext {
        let templates = try await houseworkTemplateClient.fetchTemplates(session.cohabitantId)
        guard let template = templates.first else {
            return .init(metadata: nil, houseworkTemplate: [])
        }

        let days = try await houseworkTemplateClient.fetchDays(session.cohabitantId, template.templateId)
        let monthlyItems: [HouseworkTemplateMonthlyItem]
        do {
            monthlyItems = try await houseworkTemplateClient.fetchMonthlyItems(
                session.cohabitantId,
                template.templateId
            )
        } catch {
            print("failed to fetch monthly housework template items: \(error)")
            monthlyItems = []
        }
        return .init(metadata: template, houseworkTemplate: days, monthlyItems: monthlyItems)
    }

    /// グループのメンバーと、その名前を取得する
    /// - Note: グループのドキュメントは購読でしか読めないため、最初に届いた値だけ使って購読をやめる。
    ///         最初の値は端末のキャッシュから届くことがあり、メンバーが入れ替わった直後は古い一覧になりうる。
    ///         名前を出すためだけに使うので、サーバーの値を待たずにそのまま使う
    public func fetchMembers(session: AppIntentSession) async throws -> CohabitantMemberList {
        let listenerId = "appIntentCohabitant-\(UUID().uuidString)"
        let stream = await cohabitantClient.addSnapshotListener(listenerId, session.cohabitantId)
        let cohabitant: CohabitantData?
        do {
            cohabitant = try await stream.first { _ in true } ?? nil
        } catch {
            await cohabitantClient.removeSnapshotListener(listenerId)
            throw error
        }
        await cohabitantClient.removeSnapshotListener(listenerId)

        var members = CohabitantMemberList(
            value: [.init(id: session.account.id, userName: session.account.userName)],
            ownId: session.account.id
        )
        for memberId in cohabitant?.members ?? [] where memberId != session.account.id {
            // 退会などで読めないメンバーは、名前を出せないので除く
            guard let account = try await accountInfoClient.fetch(memberId) else { continue }
            members.insert(.init(id: account.id, userName: account.userName))
        }
        return members
    }

    /// グループのいつもの家事を取得する
    /// - Note: いつもの家事は購読でしか読めないため、最初に届いた値だけ使って購読をやめる。
    ///         最初の値は端末のキャッシュから届くことがあり、同居人が追加した直後は古い一覧になりうる。
    ///         似ている家事を提案するためだけに使うので、サーバーの値を待たずにそのまま使う。
    ///         カスタムカテゴリは提案に使わないため取得しない
    public func fetchFrequentHousework(session: AppIntentSession) async -> FrequentHouseworkContext {
        let listenerId = "appIntentFrequentHousework-\(UUID().uuidString)"
        let stream = await frequentHouseworkClient.addItemsSnapshotListener(listenerId, session.cohabitantId)
        let items = await stream.first { _ in true } ?? []
        await frequentHouseworkClient.removeListener(listenerId)
        return .init(items: items)
    }

}
