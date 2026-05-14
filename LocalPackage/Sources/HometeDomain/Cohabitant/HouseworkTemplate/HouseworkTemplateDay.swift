import Foundation

public struct HouseworkTemplateDay: Codable, Sendable, Equatable, Hashable {

    /// 曜日 (0=日曜, 6=土曜)
    public let dayOfWeek: Int
    public let items: [HouseworkTemplateItem]

    public init(dayOfWeek: Int, items: [HouseworkTemplateItem]) {
        self.dayOfWeek = dayOfWeek
        self.items = items
    }

    public func applyTemplate(
        registeredItems: [HouseworkItem],
        selectedDate: Date,
        calendar: Calendar,
        uuidGenerator: () -> UUID
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
                id: uuidGenerator().uuidString,
                title: $0.title,
                point: $0.point,
                metaData: .init(selectedDate: selectedDate, calendar: calendar),
                templateHouseworkItemId: $0.id
            )
        }
        return registeredItems + incompleteTemplateItems
    }

}
