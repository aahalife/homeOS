//
//  Item.swift
//  moments
//
//  Created by BHARATH SUDHARSAN on 1/15/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
