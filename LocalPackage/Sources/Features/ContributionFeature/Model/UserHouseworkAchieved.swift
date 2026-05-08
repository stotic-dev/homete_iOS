//
//  UserHouseworkAchieved.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

struct UserHouseworkAchieved: Hashable, Identifiable {
    
    let userId: String
    let userName: String
    /// 達成した家事の数
    let achievedCount: Int
    
    var id: String { userId }
}
