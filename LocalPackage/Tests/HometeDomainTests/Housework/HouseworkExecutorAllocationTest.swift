//
//  HouseworkExecutorAllocationTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

// swiftlint:disable file_length

enum HouseworkExecutorAllocationTest {

    struct InitCase {}
    struct ToggleCase {}
    struct UpdatePercentageCase {}
    struct PointsCase {}
    struct ValidationCase {}
    struct MakeExecutorsCase {}

}

// MARK: - InitCase

extension HouseworkExecutorAllocationTest.InitCase {

    @Test("選んだ担当者はメンバー一覧の並び順に並び、割合は均等割りになる")
    func init_selectedIds_ordersByMemberIdsAndSplitsEvenly() {
        // Arrange
        let memberIds = ["own", "userB", "userC"]

        // Act
        let actual = HouseworkExecutorAllocation(
            memberIds: memberIds,
            selectedIds: ["userC", "own"],
            totalPoint: 10
        )

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 50),
            .init(userId: "userC", percentage: 50)
        ]
        #expect(actual.entries == expected)
    }

    @Test("割り切れない割合は、メンバー一覧の並び順で前の人から1%ずつ足す")
    func init_threeExecutors_givesRemainderToFirstMember() {
        // Arrange
        let memberIds = ["own", "userB", "userC"]

        // Act
        let actual = HouseworkExecutorAllocation(
            memberIds: memberIds,
            selectedIds: memberIds,
            totalPoint: 10
        )

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 34),
            .init(userId: "userB", percentage: 33),
            .init(userId: "userC", percentage: 33)
        ]
        #expect(actual.entries == expected)
    }

    @Test("家事のポイントより多い人数を選んでいると、先頭から上限の人数までに切り詰める")
    func init_selectedMoreThanPoint_truncatesToMaxCount() {
        // Arrange
        let memberIds = ["own", "userB", "userC"]

        // Act
        let actual = HouseworkExecutorAllocation(
            memberIds: memberIds,
            selectedIds: memberIds,
            totalPoint: 2
        )

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 50),
            .init(userId: "userB", percentage: 50)
        ]
        #expect(actual.entries == expected)
    }

}

// MARK: - ToggleCase

extension HouseworkExecutorAllocationTest.ToggleCase {

    @Test("未選択のメンバーを選ぶと、担当者に加わって均等割りをやり直す")
    func toggle_unselectedMember_addsAndSplitsEvenly() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userC"],
            totalPoint: 10
        )
        sut.updatePercentage(80, for: "own")

        // Act
        sut.toggle("userB")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 34),
            .init(userId: "userB", percentage: 33),
            .init(userId: "userC", percentage: 33)
        ]
        #expect(sut.entries == expected)
    }

    @Test("選択済みの担当者を外すと、残りの担当者で均等割りをやり直す")
    func toggle_selectedMember_removesAndSplitsEvenly() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            totalPoint: 10
        )

        // Act
        sut.toggle("own")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "userB", percentage: 50),
            .init(userId: "userC", percentage: 50)
        ]
        #expect(sut.entries == expected)
    }

    @Test("人数の上限に達していると、未選択のメンバーは選べない")
    func toggle_reachedMaxCount_doesNotAdd() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own"],
            totalPoint: 1
        )

        // Act
        sut.toggle("userB")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 100)
        ]
        #expect(sut.entries == expected)
    }

    @Test("最後の担当者も外せる")
    func toggle_lastExecutor_removesAll() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own"],
            totalPoint: 10
        )

        // Act
        sut.toggle("own")

        // Assert
        #expect(sut.entries == [])
    }

}

// MARK: - UpdatePercentageCase

extension HouseworkExecutorAllocationTest.UpdatePercentageCase {

    @Test("担当者が2人のとき、片方を変えるともう片方が100%の残りになる")
    func updatePercentage_twoExecutors_adjustsOther() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own", "userB"],
            totalPoint: 10
        )

        // Act
        sut.updatePercentage(70, for: "userB")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 30),
            .init(userId: "userB", percentage: 70)
        ]
        #expect(sut.entries == expected)
    }

    @Test("担当者が3人以上のとき、他の人の割合は変えない")
    func updatePercentage_threeExecutors_keepsOthers() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            totalPoint: 10
        )

        // Act
        sut.updatePercentage(50, for: "own")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 50),
            .init(userId: "userB", percentage: 33),
            .init(userId: "userC", percentage: 33)
        ]
        #expect(sut.entries == expected)
    }

    @Test("ピッカーの範囲外の割合は、範囲内に丸める")
    func updatePercentage_outOfRange_clamps() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own", "userB"],
            totalPoint: 10
        )

        // Act
        sut.updatePercentage(100, for: "own")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 99),
            .init(userId: "userB", percentage: 1)
        ]
        #expect(sut.entries == expected)
    }

    @Test("担当者が1人のときは、割合を変えられない")
    func updatePercentage_singleExecutor_doesNothing() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own"],
            totalPoint: 10
        )

        // Act
        sut.updatePercentage(50, for: "own")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 100)
        ]
        #expect(sut.entries == expected)
    }

}

// MARK: - PointsCase

extension HouseworkExecutorAllocationTest.PointsCase {

    @Test("10ptを3人で均等割りすると、4・3・3ptになる")
    func points_evenSplitWithRemainder_givesLeftoverToFirst() {
        // Arrange
        let sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            totalPoint: 10
        )

        // Act
        let actual = sut.points

        // Assert
        #expect(actual == [4, 3, 3])
    }

    @Test("余ったポイントは、小数部分が大きい人から順に配る")
    func points_largestRemainder_givesLeftoverByRemainder() {
        // Arrange
        // 7pt × 45% = 3.15、7pt × 55% = 3.85 → 切り捨てで3・3、余り1ptは小数部分が大きい2人目へ
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own", "userB"],
            totalPoint: 7
        )
        sut.updatePercentage(45, for: "own")

        // Act
        let actual = sut.points

        // Assert
        #expect(actual == [3, 4])
    }

    @Test("割合の合計が100%でないときは、ポイントを換算しない")
    func points_totalNotHundred_returnsEmpty() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            totalPoint: 10
        )
        sut.updatePercentage(50, for: "own")

        // Act
        let actual = sut.points

        // Assert
        #expect(actual == [])
    }

}

// MARK: - ValidationCase

extension HouseworkExecutorAllocationTest.ValidationCase {

    @Test("担当者が0人のときは確定できない")
    func validationError_noExecutor() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own"],
            selectedIds: ["own"],
            totalPoint: 10
        )
        sut.toggle("own")

        // Act
        let actual = sut.validationError

        // Assert
        #expect(actual == .noExecutor)
    }

    @Test("割合の合計が100%でないときは確定できない")
    func validationError_percentageNotHundred() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            totalPoint: 10
        )
        sut.updatePercentage(24, for: "own")

        // Act
        let actual = sut.validationError

        // Assert
        #expect(actual == .percentageNotHundred(total: 90))
    }

    @Test("0ptになる担当者がいるときは確定できない")
    func validationError_zeroPoint() {
        // Arrange
        // 10pt × 95% = 9.5、10pt × 5% = 0.5 → 余り1ptは同率なので先頭へ配り、10・0ptになる
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own", "userB"],
            totalPoint: 10
        )
        sut.updatePercentage(95, for: "own")

        // Act
        let actual = sut.validationError

        // Assert
        #expect(actual == .zeroPoint)
    }

    @Test("全員が1pt以上で、割合の合計が100%なら確定できる")
    func validationError_valid_returnsNil() {
        // Arrange
        let sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            totalPoint: 3
        )

        // Act
        let actual = sut.validationError

        // Assert
        #expect(actual == nil)
    }

}

// MARK: - MakeExecutorsCase

extension HouseworkExecutorAllocationTest.MakeExecutorsCase {

    @Test("確定できる配分なら、割合と換算したポイントを持つ担当者を作る")
    func makeExecutors_valid_returnsExecutors() throws {
        // Arrange
        let sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            totalPoint: 10
        )

        // Act
        let actual = try sut.makeExecutors()

        // Assert
        let expected = [
            HouseworkExecutor(userId: "own", percentage: 34, point: 4),
            HouseworkExecutor(userId: "userB", percentage: 33, point: 3),
            HouseworkExecutor(userId: "userC", percentage: 33, point: 3)
        ]
        #expect(actual == expected)
    }

    @Test("確定できない配分なら、その理由をエラーとして投げる")
    func makeExecutors_invalid_throws() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own", "userB"],
            totalPoint: 10
        )
        sut.updatePercentage(95, for: "own")

        // Act & Assert
        #expect(throws: HouseworkExecutorAllocationError.zeroPoint) {
            try sut.makeExecutors()
        }
    }

}

// swiftlint:enable file_length
