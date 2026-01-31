//
//  PushNotificationContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/12.
//

struct PushNotificationContent: Equatable {
    let title: String
    let message: String
}

extension PushNotificationContent {
    
    static func approvedMessage(reviwerName: String, houseworkTitle: String, comment: String) -> Self {
        return .init(
            title: "\(reviwerName)が「\(houseworkTitle)」を承認しました！",
            message: comment
        )
    }
}
