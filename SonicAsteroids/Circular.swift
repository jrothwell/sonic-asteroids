//
//  Circular.swift
//  SonicAsteroids
//
//  Created by DevStopFix on 15/04/2019.
//  Copyright © 2019 Zuhlke UK. All rights reserved.
//

import Foundation

class CircularCountingList {
    var size: Int
    var counts: [Int]
    var index = 0
    
    init(withSize size: Int) {
        self.size = size
        counts = Array(repeating: 0, count: size)
    }
    
    func add(_ n: Int) {
        counts[index] = n
        index += 1
        if index >= size {
            index = 0
        }
    }
    
    func sum() -> Int {
        return counts.reduce(0, +)
    }
    
    func max() -> Int? {
        return counts.max()
    }
}
