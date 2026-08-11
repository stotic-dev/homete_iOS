//
//  HouseworkStoragePolicyTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

enum HouseworkStoragePolicyTest {

    struct ViewableCase {}
    struct BoardCase {}
    struct ExpiredAtCase {}
    struct InitialFetchCase {}

}

// MARK: 閲覧範囲

extension HouseworkStoragePolicyTest.ViewableCase {

    private var calendar: Calendar {
        .japanese
    }

    @Test("isPremiumがtrueならpremium、falseならfreeになる", arguments: [true, false])
    func initWithIsPremium(isPremium: Bool) {
        // Arrange

        let expected: HouseworkStoragePolicy = isPremium ? .premium : .free

        // Act

        let actual = HouseworkStoragePolicy(isPremium: isPremium)

        // Assert

        #expect(actual == expected)
    }

    @Test("無料プランの閲覧可能な下限は当日の3ヶ月前になる")
    func freeViewableLowerBound() {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let expected = Date.previewDate(year: 2026, month: 5, day: 11)

        // Act

        let actual = HouseworkStoragePolicy.free.viewableLowerBound(currentDate: now, calendar: calendar)

        // Assert

        #expect(actual == expected)
    }

    @Test("プレミアムプランの閲覧可能な下限はnil（無制限）になる")
    func premiumViewableLowerBound() {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)

        // Act

        let actual = HouseworkStoragePolicy.premium.viewableLowerBound(currentDate: now, calendar: calendar)

        // Assert

        #expect(actual == nil)
    }

    @Test("無料プランでは下限ちょうどの日付は閲覧できる")
    func freeIsViewableOnLowerBound() {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let target = Date.previewDate(year: 2026, month: 5, day: 11)

        // Act

        let actual = HouseworkStoragePolicy.free.isViewable(target, currentDate: now, calendar: calendar)

        // Assert

        #expect(actual == true)
    }

    @Test("無料プランでは下限の1日前は閲覧できない")
    func freeIsViewableBeforeLowerBound() {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let target = Date.previewDate(year: 2026, month: 5, day: 10)

        // Act

        let actual = HouseworkStoragePolicy.free.isViewable(target, currentDate: now, calendar: calendar)

        // Assert

        #expect(actual == false)
    }

    @Test("プレミアムプランでは何年前の日付でも閲覧できる")
    func premiumIsViewable() {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let target = Date.previewDate(year: 2010, month: 1, day: 1)

        // Act

        let actual = HouseworkStoragePolicy.premium.isViewable(target, currentDate: now, calendar: calendar)

        // Assert

        #expect(actual == true)
    }

}

// MARK: 家事ボード

extension HouseworkStoragePolicyTest.BoardCase {

    @Test("無料プランの家事ボードは過去30日まで遡れる")
    func freeBoardBackwardDays() {
        // Act

        let actual = HouseworkStoragePolicy.free.boardBackwardDays

        // Assert

        #expect(actual == 30)
    }

    @Test("プレミアムプランの家事ボードの遡り日数はnil（無制限）になる")
    func premiumBoardBackwardDays() {
        // Act

        let actual = HouseworkStoragePolicy.premium.boardBackwardDays

        // Assert

        #expect(actual == nil)
    }

}

// MARK: 保持期限

extension HouseworkStoragePolicyTest.ExpiredAtCase {

    private var calendar: Calendar {
        .japanese
    }

    @Test("無料プランの保持期限は起点の1年後になる")
    func freeExpiredAt() {
        // Arrange

        let baseDate = Date.previewDate(year: 2026, month: 8, day: 11)
        let expected = Date.previewDate(year: 2027, month: 8, day: 11)

        // Act

        let actual = HouseworkStoragePolicy.free.expiredAt(from: baseDate, calendar: calendar)

        // Assert

        #expect(actual == expected)
    }

    @Test("プレミアムプランの保持期限は起点の100年後になる")
    func premiumExpiredAt() {
        // Arrange

        let baseDate = Date.previewDate(year: 2026, month: 8, day: 11)
        let expected = Date.previewDate(year: 2126, month: 8, day: 11)

        // Act

        let actual = HouseworkStoragePolicy.premium.expiredAt(from: baseDate, calendar: calendar)

        // Assert

        #expect(actual == expected)
    }

}

// MARK: 起動時フェッチ範囲

extension HouseworkStoragePolicyTest.InitialFetchCase {

    private var calendar: Calendar {
        .japanese
    }

    @Test("無料プランの起動時フェッチ範囲は3ヶ月前からになる")
    func freeInitialFetchLowerBound() {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let expected = Date.previewDate(year: 2026, month: 5, day: 11)

        // Act

        let actual = HouseworkStoragePolicy.free.initialFetchLowerBound(currentDate: now, calendar: calendar)

        // Assert

        #expect(actual == expected)
    }

    @Test("プレミアムプランの起動時フェッチ範囲は1年前からになる")
    func premiumInitialFetchLowerBound() {
        // Arrange

        let now = Date.previewDate(year: 2026, month: 8, day: 11)
        let expected = Date.previewDate(year: 2025, month: 8, day: 11)

        // Act

        let actual = HouseworkStoragePolicy.premium.initialFetchLowerBound(currentDate: now, calendar: calendar)

        // Assert

        #expect(actual == expected)
    }

}
