//
//  P2PScannerClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//

protocol P2PScannerClient {
    
    /// スキャンを開始
    func startScan()
    /// スキャンを終了
    func finishScan()
}

final class P2PScannerClientMock: P2PScannerClient {
        
    func startScan() {}
    
    func finishScan() {}
}
