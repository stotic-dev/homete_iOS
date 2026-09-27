//
//  FrequentHouseworkEditInputTest.swift
//  LocalPackage
//

@testable import FrequentHouseworkFeature
import HometeDomain
import Testing

enum FrequentHouseworkEditInputTest {

    struct InitCase {}
    struct ValidationCase {}

}

extension FrequentHouseworkEditInputTest.InitCase {

    @Test("編集する家事から作ると、名前・ポイント・カテゴリをそのまま入力値にする")
    func initFromItemCopiesValues() {
        // Arrange

        let item = FrequentHouseworkItem.makeForPreview(
            id: "1",
            title: "布団干し",
            point: 20,
            categoryId: "preset.laundry"
        )
        let expected = FrequentHouseworkEditInput(title: "布団干し", point: 20, categoryId: "preset.laundry")

        // Act

        let actual = FrequentHouseworkEditInput(item: item, context: .init(items: [item]))

        // Assert

        #expect(actual == expected)
    }

    @Test("削除済みのカテゴリを指している家事から作ると、カテゴリは「その他（未設定）」にする")
    func initFromItemWithDeletedCategoryIsUncategorized() {
        // Arrange

        let item = FrequentHouseworkItem.makeForPreview(id: "1", title: "散歩", categoryId: "deleted")
        let expected = FrequentHouseworkEditInput(title: "散歩", point: 10, categoryId: nil)

        // Act

        let actual = FrequentHouseworkEditInput(item: item, context: .init(items: [item]))

        // Assert

        #expect(actual == expected)
    }

}

extension FrequentHouseworkEditInputTest.ValidationCase {

    @Test("新規追加では、既存と同じ名前を重複と判定する")
    func validationForCreate() {
        // Arrange

        let context = FrequentHouseworkContext(items: [.makeForPreview(id: "1", title: "洗濯")])
        let input = FrequentHouseworkEditInput(title: "洗濯 ", point: 10, categoryId: nil)

        // Act

        let actual = input.validation(context: context, editingId: nil)

        // Assert

        #expect(actual == .duplicatedTitle)
    }

    @Test("編集では、自分自身と同じ名前のままでも決定できると判定する")
    func validationForEditIgnoresSelf() {
        // Arrange

        let context = FrequentHouseworkContext(items: [.makeForPreview(id: "1", title: "洗濯")])
        let input = FrequentHouseworkEditInput(title: "洗濯", point: 30, categoryId: nil)

        // Act

        let actual = input.validation(context: context, editingId: "1")

        // Assert

        #expect(actual == .valid("洗濯"))
    }

}
