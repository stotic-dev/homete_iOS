//
//  Account.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import Foundation
@testable import homete

extension AccountListenerStream {
    
    static func defaultValue() -> Self {
        
        let (stream, continuation) = AsyncStream<AccountAuthResult?>.makeStream()
        return .init(values: stream, listenerToken: NSObject(), continuation: continuation)
    }
}
