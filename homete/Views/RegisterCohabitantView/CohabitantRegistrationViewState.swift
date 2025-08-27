//
//  CohabitantRegistrationViewState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//

enum CohabitantRegistrationViewState {
    
    /// 同居人となるメンバーを探している状態
    case scanning
    /// 同居人を登録する処理を行っている状態
    case processing(isLead: Bool)
    /// 同居人の登録が完了
    case completed
}
