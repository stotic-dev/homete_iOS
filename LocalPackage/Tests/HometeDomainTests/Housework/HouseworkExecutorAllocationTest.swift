// swiftlint:disable file_length
//
//  HouseworkExecutorAllocationTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

enum HouseworkExecutorAllocationTest {

    struct InitCase {}
    struct ToggleCase {}
    struct UpdatePercentageCase {}
    struct PointsCase {}
    struct ValidationCase {}
    struct MakeExecutorsCase {}
    struct EffortCase {}
    struct ForAddingExecutorsCase {}
    struct CanAddExecutorCase {}

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
            basePoint: 10
        )

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 50),
            .init(userId: "userC", percentage: 50),
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
            basePoint: 10
        )

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 34),
            .init(userId: "userB", percentage: 33),
            .init(userId: "userC", percentage: 33),
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
            basePoint: 2
        )

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 50),
            .init(userId: "userB", percentage: 50),
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
            basePoint: 10
        )
        sut.updatePercentage(80, for: "own")

        // Act
        sut.toggle("userB")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 34),
            .init(userId: "userB", percentage: 33),
            .init(userId: "userC", percentage: 33),
        ]
        #expect(sut.entries == expected)
    }

    @Test("選択済みの担当者を外すと、残りの担当者で均等割りをやり直す")
    func toggle_selectedMember_removesAndSplitsEvenly() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            basePoint: 10
        )

        // Act
        sut.toggle("own")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "userB", percentage: 50),
            .init(userId: "userC", percentage: 50),
        ]
        #expect(sut.entries == expected)
    }

    @Test("人数の上限に達していると、未選択のメンバーは選べない")
    func toggle_reachedMaxCount_doesNotAdd() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own"],
            basePoint: 1
        )

        // Act
        sut.toggle("userB")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 100),
        ]
        #expect(sut.entries == expected)
    }

    @Test("最後の担当者も外せる")
    func toggle_lastExecutor_removesAll() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own"],
            basePoint: 10
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
            basePoint: 10
        )

        // Act
        sut.updatePercentage(70, for: "userB")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 30),
            .init(userId: "userB", percentage: 70),
        ]
        #expect(sut.entries == expected)
    }

    @Test("担当者が3人以上のとき、他の人の割合は変えない")
    func updatePercentage_threeExecutors_keepsOthers() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            basePoint: 10
        )

        // Act
        sut.updatePercentage(50, for: "own")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 50),
            .init(userId: "userB", percentage: 33),
            .init(userId: "userC", percentage: 33),
        ]
        #expect(sut.entries == expected)
    }

    @Test("ピッカーの範囲外の割合は、範囲内に丸める")
    func updatePercentage_outOfRange_clamps() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own", "userB"],
            basePoint: 10
        )

        // Act
        sut.updatePercentage(100, for: "own")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 99),
            .init(userId: "userB", percentage: 1),
        ]
        #expect(sut.entries == expected)
    }

    @Test("担当者が1人のときは、割合を変えられない")
    func updatePercentage_singleExecutor_doesNothing() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own"],
            basePoint: 10
        )

        // Act
        sut.updatePercentage(50, for: "own")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 100),
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
            basePoint: 10
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
            basePoint: 7
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
            basePoint: 10
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
            basePoint: 10
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
            basePoint: 10
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
            basePoint: 10
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
            basePoint: 3
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
            basePoint: 10
        )

        // Act
        let actual = try sut.makeExecutors()

        // Assert
        let expected = [
            HouseworkExecutor(userId: "own", percentage: 34, point: 4),
            HouseworkExecutor(userId: "userB", percentage: 33, point: 3),
            HouseworkExecutor(userId: "userC", percentage: 33, point: 3),
        ]
        #expect(actual == expected)
    }

    @Test("確定できない配分なら、その理由をエラーとして投げる")
    func makeExecutors_invalid_throws() {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own", "userB"],
            basePoint: 10
        )
        sut.updatePercentage(95, for: "own")

        // Act & Assert
        #expect(throws: HouseworkExecutorAllocationError.zeroPoint) {
            try sut.makeExecutors()
        }
    }

}

// MARK: - EffortCase

extension HouseworkExecutorAllocationTest.EffortCase {

    @Test("頑張り度を変えると、担当者と割合はそのままで、上乗せ後のポイントを配分する")
    func updateEffort_keepsEntriesAndAllocatesBoostedPoint() throws {
        // Arrange
        var sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own", "userB"],
            basePoint: 10
        )
        sut.updatePercentage(70, for: "own")

        // Act
        sut.updateEffort(.hard)

        // Assert
        // 12pt × 70% = 8.4、12pt × 30% = 3.6 → 8・4
        let actual = try sut.makeExecutors()
        let expected = [
            HouseworkExecutor(userId: "own", percentage: 70, point: 8),
            HouseworkExecutor(userId: "userB", percentage: 30, point: 4),
        ]
        #expect(actual == expected)
    }

    @Test("選べる人数の上限は、頑張り度で上乗せする前のポイントで決める")
    func canToggle_usesBasePointForMaxCount() {
        // Arrange
        // 2ptの家事は超頑張ったで3ptになるが、選べるのは2人まで
        let sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB"],
            basePoint: 2,
            effort: .veryHard
        )

        // Act
        let actual = sut.canToggle("userC")

        // Assert
        #expect(actual == false)
    }

    @Test("上乗せ後のポイントを、最大剰余方式で担当者に配分する")
    func makeExecutors_withEffort_allocatesBoostedPoint() throws {
        // Arrange
        // 10pt × 1.5 = 15pt を 34・33・33% で分ける → 5.1・4.95・4.95 → 5・5・5
        let sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB", "userC"],
            selectedIds: ["own", "userB", "userC"],
            basePoint: 10,
            effort: .veryHard
        )

        // Act
        let actual = try sut.makeExecutors()

        // Assert
        let expected = [
            HouseworkExecutor(userId: "own", percentage: 34, point: 5),
            HouseworkExecutor(userId: "userB", percentage: 33, point: 5),
            HouseworkExecutor(userId: "userC", percentage: 33, point: 5),
        ]
        #expect(actual == expected)
    }

}

// MARK: - ForAddingExecutorsCase

extension HouseworkExecutorAllocationTest.ForAddingExecutorsCase {

    @Test("もともとの担当者は、保存済みの割合と並び順のまま並ぶ")
    func forAddingExecutors_keepsSavedPercentageAndOrder() {
        // Arrange
        // メンバー一覧の並び順（own → userB → userC）とは違う順で保存された担当者
        let executors = [
            HouseworkExecutor(userId: "userC", percentage: 30, point: 3),
            HouseworkExecutor(userId: "own", percentage: 70, point: 7),
        ]

        // Act
        let actual = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "userB", "userC"],
            executors: executors,
            earnedPoint: 10
        )

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "userC", percentage: 30),
            .init(userId: "own", percentage: 70),
        ]
        #expect(actual.entries == expected)
    }

    @Test("見ている人によらず、保存済みのポイントをそのまま再現する")
    func forAddingExecutors_reproducesSavedPoints() throws {
        // Arrange
        // 15ptを50%ずつで分けると端数が1pt出るため、並び順が変わるとポイントが入れ替わる
        let executors = [
            HouseworkExecutor(userId: "userB", percentage: 50, point: 8),
            HouseworkExecutor(userId: "own", percentage: 50, point: 7),
        ]
        let sut = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "userB"],
            executors: executors,
            earnedPoint: 15
        )

        // Act
        let actual = try sut.makeExecutors()

        // Assert
        #expect(actual == executors)
    }

    @Test("メンバー一覧に居ない担当者がいる家事では、担当者を足せない")
    func forAddingExecutors_withUnknownExecutor_cannotAddExecutor() {
        // Arrange
        // 3人で担当した後に1人がアカウントを削除すると、executorsにだけ残る
        let executors = [
            HouseworkExecutor(userId: "own", percentage: 50, point: 5),
            HouseworkExecutor(userId: "deleted", percentage: 50, point: 5),
        ]
        let sut = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "userB"],
            executors: executors,
            earnedPoint: 10
        )

        // Act
        let actual = sut.canAddExecutor

        // Assert
        #expect(actual == false)
    }

    @Test("均等割りの家事では、保存済みの割合がそのまま並ぶ")
    func forAddingExecutors_keepsSavedPercentage() {
        // Arrange
        let executors = [
            HouseworkExecutor(userId: "own", percentage: 70, point: 7),
            HouseworkExecutor(userId: "userC", percentage: 30, point: 3),
        ]

        // Act
        let actual = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "userB", "userC"],
            executors: executors,
            earnedPoint: 10
        )

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 70),
            .init(userId: "userC", percentage: 30),
        ]
        #expect(actual.entries == expected)
    }

    @Test("もともとの担当者は外せない")
    func forAddingExecutors_cannotToggleExistingExecutor() {
        // Arrange
        let sut = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "userB"],
            executors: [.solo(userId: "own", point: 10)],
            earnedPoint: 10
        )

        // Act
        let actual = sut.canToggle("own")

        // Assert
        #expect(actual == false)
    }

    @Test("もともとの担当者を外そうとしても、担当者と割合は変わらない")
    func toggle_lockedExecutor_keepsEntries() {
        // Arrange
        var sut = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "userB"],
            executors: [.solo(userId: "own", point: 10)],
            earnedPoint: 10
        )

        // Act
        sut.toggle("own")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 100),
        ]
        #expect(sut.entries == expected)
    }

    @Test("手伝った人を足すと、もともとの割合は捨てて全員を均等割りにし直す")
    func toggle_addsHelper_splitsEvenly() {
        // Arrange
        let executors = [
            HouseworkExecutor(userId: "own", percentage: 70, point: 7),
            HouseworkExecutor(userId: "userC", percentage: 30, point: 3),
        ]
        var sut = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "userB", "userC"],
            executors: executors,
            earnedPoint: 10
        )

        // Act
        sut.toggle("userB")

        // Assert
        let expected: [HouseworkExecutorAllocation.Entry] = [
            .init(userId: "own", percentage: 34),
            .init(userId: "userB", percentage: 33),
            .init(userId: "userC", percentage: 33),
        ]
        #expect(sut.entries == expected)
    }

    @Test("配分し直しても、担当者のポイントの合計は上乗せ後のポイントのまま変わらない")
    func makeExecutors_afterAddingHelper_keepsEarnedPoint() throws {
        // Arrange
        // 頑張り度で15ptに上乗せされた家事に、3人目を足して均等割りにする → 5・5・5
        var sut = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "userB", "userC"],
            executors: [
                .init(userId: "own", percentage: 50, point: 8),
                .init(userId: "userC", percentage: 50, point: 7),
            ],
            earnedPoint: 15
        )
        sut.toggle("userB")

        // Act
        let actual = try sut.makeExecutors()

        // Assert
        let expected = [
            HouseworkExecutor(userId: "own", percentage: 34, point: 5),
            HouseworkExecutor(userId: "userB", percentage: 33, point: 5),
            HouseworkExecutor(userId: "userC", percentage: 33, point: 5),
        ]
        #expect(actual == expected)
    }

    @Test("足せる人数の上限は、上乗せ後のポイントで決める")
    func forAddingExecutors_usesEarnedPointForMaxCount() {
        // Arrange
        // 1ptの家事を超頑張ったで完了して2ptになっていれば、2人目を足せる
        let sut = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "userB"],
            executors: [.solo(userId: "own", point: 2)],
            earnedPoint: 2
        )

        // Act
        let actual = sut.canToggle("userB")

        // Assert
        #expect(actual == true)
    }

}

// MARK: - CanAddExecutorCase

extension HouseworkExecutorAllocationTest.CanAddExecutorCase {

    @Test("未選択のメンバーがいて人数の上限に達していなければ、担当者を足せる")
    func canAddExecutor_hasUnselectedMemberUnderLimit_returnsTrue() {
        // Arrange
        let sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own"],
            basePoint: 10
        )

        // Act
        let actual = sut.canAddExecutor

        // Assert
        #expect(actual == true)
    }

    @Test("メンバー全員が担当者になっていると、担当者を足せない")
    func canAddExecutor_allMembersSelected_returnsFalse() {
        // Arrange
        let sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own", "userB"],
            basePoint: 10
        )

        // Act
        let actual = sut.canAddExecutor

        // Assert
        #expect(actual == false)
    }

    @Test("人数の上限に達していると、未選択のメンバーがいても担当者を足せない")
    func canAddExecutor_reachedMaxCount_returnsFalse() {
        // Arrange
        let sut = HouseworkExecutorAllocation(
            memberIds: ["own", "userB"],
            selectedIds: ["own"],
            basePoint: 1
        )

        // Act
        let actual = sut.canAddExecutor

        // Assert
        #expect(actual == false)
    }

}
