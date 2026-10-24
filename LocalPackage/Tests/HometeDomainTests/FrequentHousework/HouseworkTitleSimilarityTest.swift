//
//  HouseworkTitleSimilarityTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct HouseworkTitleSimilarityTest {

    @Test(
        "空白・カタカナとひらがな・全角と半角・大文字と小文字の違いはそろえて比べる",
        arguments: [
            ("洗濯 物干し", "洗濯物干し"),
            ("ゴミ出し", "ごみ出し"),
            ("ｺﾞﾐ出し", "ごみ出し"),
            ("ＰＣ掃除", "pc掃除"),
        ]
    )
    func normalized(input: String, expected: String) {
        // Act

        let actual = HouseworkTitleSimilarity.normalized(input)

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "言い方が違っても似ている名前は、似ているとみなす",
        arguments: [
            ("洗濯干した", "洗濯物干し"),
            ("洗濯物を干した", "洗濯物干し"),
            ("買い物行く", "買い物"),
            ("ゴミ出し", "ごみ出し"),
        ]
    )
    func similar(spoken: String, title: String) {
        // Act

        let actual = HouseworkTitleSimilarity.score(spoken, title)

        // Assert

        #expect(actual >= HouseworkTitleSimilarity.threshold)
    }

    @Test(
        "関係のない名前は、似ているとみなさない",
        arguments: [
            ("皿洗い", "洗濯"),
            ("買い物", "お風呂掃除"),
            ("皿", "皿洗い"),
            ("", "洗濯"),
        ]
    )
    func notSimilar(spoken: String, title: String) {
        // Act

        let actual = HouseworkTitleSimilarity.score(spoken, title)

        // Assert

        #expect(actual < HouseworkTitleSimilarity.threshold)
    }

    @Test("似ているいつもの家事を、似ている順に返す")
    func similarItems() {
        // Arrange

        let laundry = FrequentHouseworkItem.makeForTest(id: "laundry", title: "洗濯物干し")
        let laundryFold = FrequentHouseworkItem.makeForTest(id: "fold", title: "洗濯物たたみ")
        let shopping = FrequentHouseworkItem.makeForTest(id: "shopping", title: "買い物")
        let context = FrequentHouseworkContext(items: [laundryFold, shopping, laundry])

        // Act

        let actual = context.similarItems(to: "洗濯物干した")

        // Assert

        #expect(actual == [laundry, laundryFold])
    }

    @Test("そろえた名前が同じいつもの家事があれば、その家事だけを返す")
    func similarItemsExact() {
        // Arrange

        let garbage = FrequentHouseworkItem.makeForTest(id: "garbage", title: "ごみ出し")
        let bigGarbage = FrequentHouseworkItem.makeForTest(id: "big", title: "粗大ごみ出し")
        let context = FrequentHouseworkContext(items: [bigGarbage, garbage])

        // Act

        let actual = context.similarItems(to: "ゴミ出し")

        // Assert

        #expect(actual == [garbage])
    }

    @Test("似ている度合いが同じなら、並び順で返し、上限の件数までに絞る")
    func similarItemsLimit() {
        // Arrange

        let items = (0 ..< 3).map {
            FrequentHouseworkItem.makeForTest(id: "\($0)", title: "お風呂掃除\($0)", sortOrder: 2 - $0)
        }
        let context = FrequentHouseworkContext(items: items)

        // Act

        let actual = context.similarItems(to: "お風呂掃除", limit: 2)

        // Assert

        #expect(actual == [items[2], items[1]])
    }

}
