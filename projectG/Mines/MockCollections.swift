//
//  MockCollections.swift
//  projectG
//
//  Created by root0 on 2022/09/19.
//

import Foundation

struct MockCollection {
    
    var city: String
    var time: String
    var noon: String
    var clock: String
    var weather: String
    var temper: String
    
}

class Mocks {
    var collections: [MockCollection] = [MockCollection]()
    
    init() {
        self.collections = [
            MockCollection(city: "레이캬비크", time: "+9", noon: "오전", clock: "5:46", weather: "초승달", temper: "6"),
            MockCollection(city: "런던", time: "+8", noon: "오전", clock: "6:46", weather: "보름달", temper: "11"),
            MockCollection(city: "서울", time: "+0", noon: "오후", clock: "2:46", weather: "구름", temper: "29"),
            MockCollection(city: "일본", time: "+0", noon: "오후", clock: "2:46", weather: "구름많음", temper: "33")
        ]
    }
    static let shared = Mocks()
}
