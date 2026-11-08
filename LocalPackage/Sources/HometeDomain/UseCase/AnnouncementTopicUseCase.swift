//
//  AnnouncementTopicUseCase.swift
//  LocalPackage
//

/// お知らせのPush通知を受け取るかどうかの設定と、FCMトピックの購読をそろえるUseCase
/// - Note: 設定の保存と購読の切り替えを1か所にまとめ、片方だけ変わった状態にならないようにする
public final class AnnouncementTopicUseCase: Sendable {

    private let client: AnnouncementTopicClient

    public init(client: AnnouncementTopicClient) {
        self.client = client
    }

    /// 起動時に、保存している設定どおりにトピックを購読する／やめる
    /// - Note: 購読は端末単位で、ログイン状態に関わらない
    public func sync() async {
        if await client.loadIsEnabled() {
            await client.subscribe()
        } else {
            await client.unsubscribe()
        }
    }

    /// お知らせの通知を受け取る設定かどうか
    public func isEnabled() async -> Bool {
        await client.loadIsEnabled()
    }

    /// 設定を保存し、トピックの購読を切り替える
    public func update(isEnabled: Bool) async {
        await client.saveIsEnabled(isEnabled)
        if isEnabled {
            await client.subscribe()
        } else {
            await client.unsubscribe()
        }
    }

}
