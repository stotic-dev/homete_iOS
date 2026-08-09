import Foundation

public struct HouseworkTemplateDay: Codable, Sendable, Equatable, Hashable {

    public let dayOfWeek: DayOfWeek
    public let items: [HouseworkTemplateItem]

    public init(dayOfWeek: DayOfWeek, items: [HouseworkTemplateItem]) {
        self.dayOfWeek = dayOfWeek
        self.items = items
    }

    public func applyTemplate(
        registeredItems: [HouseworkItem],
        selectedDate: Date,
        calendar: Calendar,
        uuidGenerator: () -> UUID
    ) -> [HouseworkItem] {
        applyTemplate(
            registeredItems: registeredItems,
            selectedDate: selectedDate,
            calendar: calendar,
            idGenerator: { _ in uuidGenerator().uuidString }
        )
    }

    /// 生成する家事のIDをテンプレートの家事から決定する`applyTemplate`
    ///
    /// 表示のたびに再計算する画面では、`uuidGenerator`版だとIDが毎回変わってViewの同一性が保てないため、
    /// テンプレートの家事から一意なIDを導出したい場合にこちらを使う。
    public func applyTemplate(
        registeredItems: [HouseworkItem],
        selectedDate: Date,
        calendar: Calendar,
        idGenerator: (HouseworkTemplateItem) -> String
    ) -> [HouseworkItem] {
        let incompleteTemplateItems = items.filter { item in
            // 登録されている家事の中で、すでにテンプレートから生成された家事があれば重複しないように弾く
            let isNotDistinct = !registeredItems.contains { $0.templateHouseworkItemId == item.id }
            // テンプレートの家事の更新日付よりも古い日付の場合は表示しない
            let isNotOldTemplateItem = calendar.startOfDay(for: selectedDate) >= calendar
                .startOfDay(for: item.updatedAt)
            return isNotDistinct && isNotOldTemplateItem
        }
        .map {
            HouseworkItem(
                id: idGenerator($0),
                title: $0.title,
                point: $0.point,
                metaData: .init(selectedDate: selectedDate, calendar: calendar),
                templateHouseworkItemId: $0.id
            )
        }
        return registeredItems + incompleteTemplateItems
    }

}
