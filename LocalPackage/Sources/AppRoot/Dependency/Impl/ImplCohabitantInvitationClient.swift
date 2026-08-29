//
//  ImplCohabitantInvitationClient.swift
//

import FirebaseFunctions
import Foundation
import HometeDomain

extension CohabitantInvitationClient {

    static let liveValue: CohabitantInvitationClient = .init {
        do {
            let result = try await Functions.functions()
                .httpsCallable("issuecohabitantinvitation")
                .call()
            return try makeInvitation(from: result.data)
        } catch {
            throw convert(error)
        }
    } join: { token in
        do {
            let result = try await Functions.functions()
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
    static func convert(_ error: any Error) -> any Error {
        let nsError = error as NSError
        guard nsError.domain == FunctionsErrorDomain,
              let code = FunctionsErrorCode(rawValue: nsError.code) else {
            return error
        }

        switch code {
        case .notFound:
            return CohabitantInvitationError.notFound

        case .deadlineExceeded:
            return CohabitantInvitationError.expired

        case .failedPrecondition:
            return CohabitantInvitationError.alreadyJoined

        default:
            return error
        }
    }

}
