//
//  TestLockedArray.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/20.
//

actor TestLockedArray<Element: Sendable> {

    var values: [Element] = []

    func append(_ element: Element) {
        values.append(element)
    }

}
