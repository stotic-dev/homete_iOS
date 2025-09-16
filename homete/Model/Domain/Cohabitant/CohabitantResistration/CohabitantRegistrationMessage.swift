//
//  CohabitantRegistrationMessage.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import Foundation

struct CohabitantRegistrationMessage: Codable, Equatable {
    
    let type: CommunicateType
    
    enum CommunicateType: Codable, Equatable {
        
        /// 登録を行うメンバーが確定したかどうかの確認
        case fixedMember(isOK: Bool)
        /// アカウントIDの共有
        case preRegistration(role: CohabitantRegistrationRole)
        /// 同居人IDの共有
        case shareCohabitantId(id: String)
        /// 登録完了したかどうかの確認
        case complete
    }
    
    /// 登録メンバーが確定したかどうか
    var isFixedMember: Bool? {
        
        guard case .fixedMember(let isOK) = type else {
            return nil
        }
        return isOK
    }
    
    /// メンバーの役割
    var memberRole: CohabitantRegistrationRole? {
        
        guard case .preRegistration(let role) = type else {
            
            return nil
        }
        return role
    }
    
    /// 同居人ID
    var cohabitantId: String? {
        
        guard case .shareCohabitantId(let id) = type else {
            
            return nil
        }
        return id
    }
    
    /// 登録処理が完了したかどうか
    var isComplete: Bool? {
        
        guard case .complete = type else {
            
            return nil
        }
        return true
    }
        
    func encodedData() -> Data {
        
        guard let encodedData = try? JSONEncoder().encode(self) else {
            
            preconditionFailure("Invalid message structure(\(self)).")
        }
        return encodedData
    }
}

extension CohabitantRegistrationMessage {
    
    init(_ data: Data) {
        
        guard let message = try? JSONDecoder().decode(CohabitantRegistrationMessage.self, from: data) else {
            
            preconditionFailure("Invalid data(\(data)).")
        }
        self = message
    }
}
