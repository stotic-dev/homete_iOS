//
//  CohabitantRegistrationState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

enum CohabitantRegistrationState {
    
    /// 初期状態
    case initial
    /// 他ユーザーを探索中
    case searching
    /// 検知したユーザーを登録中
    case registering(isSenderRole: Bool)
    /// 同居人の登録完了
    case registered
    /// エラー発生
    case error
}
