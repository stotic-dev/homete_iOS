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
    /// 検知したユーザーを登録中
    case registering
    /// 同居人の登録完了
    case completed
}

enum CohabitantRegistrationSessionResponse {
    
    /// 他ユーザーを探索中
    case searching(connectedDeviceNameList: [String])
    /// 接続メンバー確定時
    case connected(isSenderRole: Bool)
    /// 同居人IDを受信
    case receivedId(CohabitantIdMessage)
    /// 登録完了
    case completed
    /// エラー発生
    case error
}
