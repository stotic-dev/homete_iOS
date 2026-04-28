import Foundation

public struct HouseworkTemplateEditor: Identifiable, Codable, Sendable, Equatable {
    public let userId: String
    public let updatedAt: Date
    /// Firestore TTL自動削除用
    public let expiredAt: Date

    public var id: String { userId }

    public init(userId: String, updatedAt: Date, expiredAt: Date) {
        self.userId = userId
        self.updatedAt = updatedAt
        self.expiredAt = expiredAt
    }

    /// updatedAt が5分以上古ければ離席済みと判断する
    public func isActive(now: Date) -> Bool {
        return now.timeIntervalSince(updatedAt) < 5 * 60
    }
}
