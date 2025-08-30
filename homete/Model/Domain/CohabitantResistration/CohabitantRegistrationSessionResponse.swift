//
//  CohabitantRegistrationSessionResponse.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/18.
//

enum CohabitantRegistrationSessionResponse {
    
    /// 他ユーザーを探索中
    case searching(connectedDeviceNameList: [String])
    /// 他メンバーから登録のリクエストを受信
    case receivedRegistrationRequest(isAllConfirmation: Bool)
    /// 同居人のアカウントIDを送信できる準備が整ったことを通知
    case readyToShareAccountId
    /// 同居人として登録するアカウントのIDを受信
    case receivedAccountId([String])
    /// 同居人IDを受信
    case receivedId
    /// 登録完了
    case completed
    /// エラー発生
    case error
}
