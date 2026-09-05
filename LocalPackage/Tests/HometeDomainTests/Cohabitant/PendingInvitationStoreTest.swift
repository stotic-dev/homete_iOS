//
//  PendingInvitationStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct PendingInvitationStoreTest {

    @Test("受け取った招待トークンを保持する")
    func store() {
        // Arrange
        let sut = PendingInvitationStore()

        // Act
        sut.store("test-token")

        // Assert
        #expect(sut.pendingToken == "test-token")
    }

    @Test("保持している招待トークンを破棄する")
    func clear() {
        // Arrange
        let sut = PendingInvitationStore(pendingToken: "test-token")

        // Act
        sut.clear()

        // Assert
        #expect(sut.pendingToken == nil)
    }

}
