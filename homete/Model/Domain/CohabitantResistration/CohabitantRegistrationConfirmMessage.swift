//
//  CohabitantRegistrationConfirmMessage.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

struct CohabitantRegistrationConfirmMessage: Codable {
    
    let response: Response
    
    enum Response: Codable {
        
        case ok
        case no
    }
}
