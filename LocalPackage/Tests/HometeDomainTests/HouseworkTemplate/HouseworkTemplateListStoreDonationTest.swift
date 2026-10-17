//
//  HouseworkTemplateListStoreDonationTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Observation
import Testing

/// テンプレートの家事が変わったときに、Siriで言える家事の名前をOSに読み直してもらう
@MainActor
struct HouseworkTemplateListStoreDonationTest {

    /// 月曜日
    private let now = Date.previewDate(year: 2026, month: 10, day: 12, hour: 9)

    @Test("今日のテンプレートの家事の名前が変わったときだけ読み直してもらい、最初に読み込んだときと名前が同じときは頼まない")
    func updateHouseworkTitles_whenTodayTitlesChange() async throws {
        // Arrange

        let initialDays = [makeDay(.monday, titles: ["ゴミ出し"])]
        let (daysStream, daysContinuation) = AsyncStream<[HouseworkTemplateDay]>.makeStream()

        try await confirmation { confirmation in
            let store = makeSUT(
                daysStream: daysStream,
                updateHouseworkTitles: { confirmation() },
                fetchDays: initialDays
            )
            try await store.configure(cohabitantId: "cohabitant")

            // Act

            // 最初に読み込んだときと同じ値は画面の更新を起こさないため、続く値を受け取り終えたかで待つ
            daysContinuation.yield(initialDays)
            // 今日ではない曜日の家事だけが変わった
            await yield(
                initialDays + [makeDay(.tuesday, titles: ["洗車"])],
                to: daysContinuation,
                observing: store
            )
            // 今日の家事の名前が変わった
            await yield(
                [makeDay(.monday, titles: ["燃えるゴミ出し"]), makeDay(.tuesday, titles: ["洗車"])],
                to: daysContinuation,
                observing: store
            )

            // Cleanup

            daysContinuation.finish()
            await store.stopObservingItems()
        }
    }

    @Test("テンプレートが無い状態で読み込んだ後、今日の家事を持つテンプレートができたら読み直してもらう")
    func updateHouseworkTitles_afterTemplateCreated() async throws {
        // Arrange

        let (daysStream, daysContinuation) = AsyncStream<[HouseworkTemplateDay]>.makeStream()

        try await confirmation { confirmation in
            let store = makeSUT(
                daysStream: daysStream,
                updateHouseworkTitles: { confirmation() },
                templates: []
            )
            try await store.configure(cohabitantId: "cohabitant")

            // Act

            await store.startObservingItems(templateId: "template", cohabitantId: "cohabitant")
            await yield([makeDay(.monday, titles: ["ゴミ出し"])], to: daysContinuation, observing: store)

            // Cleanup

            daysContinuation.finish()
            await store.stopObservingItems()
        }
    }

}

private extension HouseworkTemplateListStoreDonationTest {

    func makeSUT(
        daysStream: AsyncStream<[HouseworkTemplateDay]>,
        updateHouseworkTitles: @escaping @Sendable () -> Void,
        templates: [HouseworkTemplateMeta] = [.init(templateId: "template", name: "default")],
        fetchDays: [HouseworkTemplateDay] = []
    ) -> HouseworkTemplateListStore {
        let now = now
        return .init(
            houseworkTemplateClient: .init(
                fetchTemplates: { _ in templates },
                fetchDays: { _, _ in fetchDays },
                addDaysSnapshotListener: { _, _, _ in daysStream }
            ),
            intentDonationClient: .init(updateHouseworkTitles: updateHouseworkTitles),
            calendar: .japanese,
            now: { now }
        )
    }

    func makeDay(_ dayOfWeek: DayOfWeek, titles: [String]) -> HouseworkTemplateDay {
        .init(
            dayOfWeek: dayOfWeek,
            items: titles.map { .init(id: .init(id: $0), title: $0, point: 10, updatedAt: now) }
        )
    }

    /// リスナーに曜日別の家事を流し、Storeが受け取り終えるまで待つ
    func yield(
        _ days: [HouseworkTemplateDay],
        to continuation: AsyncStream<[HouseworkTemplateDay]>.Continuation,
        observing store: HouseworkTemplateListStore
    ) async {
        let waiter = Task {
            await withCheckedContinuation { continuation in
                withObservationTracking {
                    _ = store.selectedDays
                } onChange: {
                    continuation.resume()
                }
            }
        }
        continuation.yield(days)
        await waiter.value
    }

}
