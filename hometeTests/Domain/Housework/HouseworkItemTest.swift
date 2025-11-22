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
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    var decoder: JSONDecoder {
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    let fullItemEncodedString = """
        {
          "executedAt" : "2024-12-31T15:00:00Z",
          "executorId" : "dummy",
          "expiredAt" : "2024-12-31T15:00:00Z",
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
        
        let inputIndexedDate = Date.dateComponents(year: 2025, month: 1, day: 1)
        let inputExecutedAt = Date.dateComponents(year: 2025, month: 1, day: 1)
        let inputExpiredAt = Date.dateComponents(year: 2025, month: 1, day: 1)
        
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
        
        let inputIndexedDate = Date.dateComponents(year: 2025, month: 1, day: 1)
        let inputExecutedAt = Date.dateComponents(year: 2025, month: 1, day: 1)
        let inputExpiredAt = Date.dateComponents(year: 2025, month: 1, day: 1)
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
