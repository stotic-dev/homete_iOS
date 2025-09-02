//
//  LaunchStateTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/02.
//

import Testing

@testable import homete

struct LaunchStateTest {

    @Test(
        "認証情報が空の場合は、未ログイン状態へ遷移する",
        arguments: [
            LaunchState.launching,
            .loggedIn(.init(id: "", displayName: "")),
            .notLoggedIn
        ]
    )
    func next_not_logged_in_case(inputState: LaunchState) async throws {
        
        let actual = inputState.next(nil)
        
        #expect(actual == .notLoggedIn)
    }
    
    @Test(
        "認証情報がある場合は、ログイン状態へ遷移する",
        arguments: [
            LaunchState.launching,
            .loggedIn(.init(id: "", displayName: "")),
            .notLoggedIn
        ]
    )
    func next_logged_in_case(inputState: LaunchState) async throws {
        
        let inputAuth = AccountAuthResult(id: "id", displayName: "name")
        
        let actual = inputState.next(inputAuth)
        
        #expect(actual == .loggedIn(inputAuth))
    }
}
