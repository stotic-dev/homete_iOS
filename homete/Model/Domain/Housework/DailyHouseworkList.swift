//
//  DailyHouseworkList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation

struct DailyHouseworkList: Equatable {
    
    let indexedDate: Date
    let metaData: DailyHouseworkMetaData
    let items: [HouseworkItem]
}
