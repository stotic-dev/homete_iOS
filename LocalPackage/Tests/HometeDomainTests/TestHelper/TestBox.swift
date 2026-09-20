//
//  TestBox.swift
//  LocalPackage
//

/// `@Sendable`な同期クロージャから、テスト中に差し替え・記録したい値を出し入れするための箱
///
/// `TestLockedArray` / `TestCounter` は actor のため同期クロージャ（`AnalyticsClient.log` など）からは使えない。
/// テスト対象の Store が `@MainActor` で、クロージャもメインアクター上で順に呼ばれる前提のときに使う（排他はしない）。
final class TestBox<Value>: @unchecked Sendable {

    var value: Value

    init(value: Value) {
        self.value = value
    }

}
