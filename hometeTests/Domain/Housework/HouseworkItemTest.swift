//
//  HouseworkItemTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/11/22.
//

import Firebase
import Foundation
import Testing
@testable import homete

struct HouseworkItemTest {
    
    var encoder: JSONEncoder {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
    
    var decoder: JSONDecoder {
        
        return JSONDecoder()
    }
    
    let fullItemEncodedString = """
        {
          "executedAt" : 757350000,
          "executorId" : "dummy",
          "expiredAt" : 757350000,
          "id" : "id1",
          "indexedDate" : "2025-01-01",
          "point" : 10,
          "state" : {
            "incomplete" : {

            }
          },
          "title" : "dummy"
        }
        """

    @Test("全ての項目が入力された家事オブジェクトをエンコードできること")
    func init_encode() async throws {
        
        let inputIndexedDate = try Date.dateComponents(year: 2025, month: 1, day: 1)
        let inputExecutedAt = try Date.dateComponents(year: 2025, month: 1, day: 1)
        let inputExpiredAt = try Date.dateComponents(year: 2025, month: 1, day: 1)
        
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: inputIndexedDate,
            title: "dummy",
            point: 10,
            state: .incomplete,
            executorId: "dummy",
            executedAt: inputExecutedAt,
            expiredAt: inputExpiredAt
        )
        
        let actual = try #require(String(data: encoder.encode(item), encoding: .utf8))
        
        #expect(actual == fullItemEncodedString)
    }
    
    @Test("全ての項目が入力された家事データをデコードできること")
    func decode() async throws {
        
        let inputData = try #require(fullItemEncodedString.data(using: .utf8))
        
        let actual = try decoder.decode(HouseworkItem.self, from: inputData)
        
        let inputIndexedDate = try Date.dateComponents(year: 2025, month: 1, day: 1)
        let inputExecutedAt = try Date.dateComponents(year: 2025, month: 1, day: 1)
        let inputExpiredAt = try Date.dateComponents(year: 2025, month: 1, day: 1)
        let expected = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: inputIndexedDate,
            title: "dummy",
            point: 10,
            state: .incomplete,
            executorId: "dummy",
            executedAt: inputExecutedAt,
            expiredAt: inputExpiredAt
        )
        #expect(actual == expected)
    }
}

extension Date {
    static func dateComponents(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = .zero,
        minute: Int = .zero,
        second: Int = .zero,
        calendar: Calendar = .current
    ) throws -> Date {
        try #require(
            DateComponents(
                calendar: calendar,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            )
            .date
        )
    }
}
