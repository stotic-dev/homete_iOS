//
//  AnalyticsEvent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

struct AnalyticsEvent {
    
    let name: String
    let parameters: [String: String]
}

extension AnalyticsEvent {
    
    static func login(isSuccess: Bool) -> Self {
        
        return .init(
            name: "login",
            parameters: ["isSuccess": "\(isSuccess)"]
        )
    }
}
