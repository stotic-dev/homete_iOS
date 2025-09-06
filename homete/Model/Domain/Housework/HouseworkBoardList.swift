//
//  HouseworkBoardList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

struct HouseworkBoardList {
    
    private(set) var items: [HouseworkItem]
    
    func items(matching state: HouseworkState) -> [HouseworkItem] {
        
        return items.filter { $0.state == state }
    }
}
