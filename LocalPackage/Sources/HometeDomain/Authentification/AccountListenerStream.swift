//
//  AccountListenerStream.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/04.
//

import Foundation

public struct AccountListenerStream {

    public let values: AsyncStream<AccountAuthResult?>
    public let listenerToken: any NSObjectProtocol
    private let continuation: AsyncStream<AccountAuthResult?>.Continuation

    public init(
        values: AsyncStream<AccountAuthResult?>,
        listenerToken: any NSObjectProtocol,
        continuation: AsyncStream<AccountAuthResult?>.Continuation
    ) {

        self.values = values
        self.listenerToken = listenerToken
        self.continuation = continuation
    }

    public func stopListening() {

        continuation.finish()
    }
}
