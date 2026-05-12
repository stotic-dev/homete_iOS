//
//  ApplyPlan.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/12.
//

import Foundation
import HometeDomain

struct ApplyPlan {
    
    let days: [HouseworkTemplateDay]
    let cohabitantId: String
    let targetDates: [Date]
    let targetIncompleteItems: [HouseworkItem]
    let calendar: Calendar
}
