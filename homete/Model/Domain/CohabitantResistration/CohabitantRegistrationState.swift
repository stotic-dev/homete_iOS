//
//  CohabitantRegistrationState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

enum CohabitantRegistrationState: Equatable {
    
    /// 初期状態
    case initial
    /// 他ユーザーを探索中
    case searching(connectedDeviceNameList: [String])
    /// 他ユーザーの確認待ち
    case waitingForConfirmation
    /// 検知したユーザーを登録中
    case registering(isLead: Bool)
    /// 同居人の登録完了
    case completed
}
