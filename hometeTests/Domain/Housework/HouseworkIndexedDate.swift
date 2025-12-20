//
//  HouseworkIndexedDate.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import Foundation
import Testing
@testable import homete

struct HouseworkIndexedDateTest {

    @Test(arguments: [
        Date.distantPast,
        .init(timeIntervalSince1970: .zero),
        .dateComponents(year: 2025, month: 1, day: 1),
        .distantFuture
    ])
    func init_parse_date(inputDate: Date) async throws {
        let indexedDate = HouseworkIndexedDate(inputDate)
        
        let expected = inputDate.formatted(
            Date.FormatStyle(date: .numeric, time: .omitted)
                .year(.extended(minimumLength: 4))
                .month(.twoDigits)
                .day(.twoDigits)
                .locale(.jp)
        )
        #expect(indexedDate.value == expected)
    }
}
