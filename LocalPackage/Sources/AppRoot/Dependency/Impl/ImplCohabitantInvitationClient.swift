//
//  ImplCohabitantInvitationClient.swift
//

import FirebaseFunctions
import Foundation
import HometeDomain
import HometeInfrastructure

extension CohabitantInvitationClient {

    static let liveValue: CohabitantInvitationClient = .init {
        do {
            let result = try await Functions.functions(region: FunctionsRegion.homete)
                .httpsCallable("issuecohabitantinvitation")
                .call()
            return try makeInvitation(from: result.data)
        } catch {
            throw convert(error)
        }
    } join: { token in
        do {
            let result = try await Functions.functions(region: FunctionsRegion.homete)
                .httpsCallable("joincohabitant")
                .call(["token": token])
            guard let response = result.data as? [String: Any],
                  let cohabitantId = response["cohabitantId"] as? String else {
                throw DomainError.other
            }
            return cohabitantId
        } catch {
            throw convert(error)
        }
    }

}

private extension CohabitantInvitationClient {

    /// callableのレスポンスから招待情報を組み立てる
    static func makeInvitation(from data: Any) throws -> CohabitantInvitation {
        guard let response = data as? [String: Any],
              let token = response["token"] as? String,
              let cohabitantId = response["cohabitantId"] as? String,
              let expiresAtMilliseconds = response["expiresAt"] as? Double else {
            throw DomainError.other
        }

        return CohabitantInvitation(
            token: token,
            cohabitantId: cohabitantId,
            // Functions側はepochミリ秒で返すため秒に直す
            expiresAt: Date(timeIntervalSince1970: expiresAtMilliseconds / 1000)
        )
    }

    /// FunctionsのHttpsErrorをドメインのエラーに変換する
    ///
    /// 招待固有の失敗かどうかはFunctionsが`details`に載せたコードだけで判別する。
    /// 標準のエラーコードで判別すると、リクエストのタイムアウト（`deadlineExceeded`）を
    /// 招待の期限切れと誤認したり、関数が未デプロイのときの`notFound`を
    /// 無効なリンクとして扱ったりしてしまうため。
    static func convert(_ error: any Error) -> any Error {
        let nsError = error as NSError
        guard nsError.domain == FunctionsErrorDomain else { return error }

        if let details = nsError.userInfo[FunctionsErrorDetailsKey] as? [String: Any],
           let serverCode = details[CohabitantInvitationError.serverCodeKey] as? String,
           let invitationError = CohabitantInvitationError(serverCode: serverCode) {
            return invitationError
        }

        guard let code = FunctionsErrorCode(rawValue: nsError.code) else { return error }

        switch code {
        case .unavailable, .deadlineExceeded:
            // 招待固有の情報が付かないこれらは、サーバに届いていないか応答が返らなかったケース
            return DomainError.noNetwork

        default:
            return error
        }
    }

}
