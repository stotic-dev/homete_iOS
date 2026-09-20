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
            let result = try await FunctionsService.call("issuecohabitantinvitation")
            return try makeInvitation(from: result.data)
        } catch {
            throw convert(error)
        }
    } join: { token in
        do {
            let result = try await FunctionsService.call("joincohabitant", parameters: ["token": token])
            guard let response = result.data as? [String: Any],
                  let cohabitantId = response["cohabitantId"] as? String,
                  let joined = response["joined"] as? Bool else {
                throw DomainError.other
            }
            return CohabitantJoinResult(cohabitantId: cohabitantId, isNewMember: joined)
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
              let expiresAtMilliseconds = response["expiresAt"] as? Double else {
            throw DomainError.other
        }

        return CohabitantInvitation(
            token: token,
            // 発行者がグループ未所属の場合はnull（NSNull）で返るため、Stringにキャストできなければnil
            cohabitantId: response["cohabitantId"] as? String,
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
           let serverCode = details[CohabitantInvitationError.serverCodeKey] as? String {
            if let invitationError = CohabitantInvitationError(serverCode: serverCode) {
                return invitationError
            }
            // Accountドキュメントがサーバーに無い（ログイン状態とFirestoreが食い違っている）ケース。
            // 再サインインでアカウント登録からやり直せるため、その案内が出る認証エラーとして扱う
            if serverCode == CohabitantInvitationError.accountNotFoundServerCode {
                return DomainError.failAuth
            }
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
