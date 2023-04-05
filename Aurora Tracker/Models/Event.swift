//
//  Event.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 3/31/23.
//

import Foundation
import SwiftUI

struct Event: Hashable, Codable, Identifiable {
    
    var id: Int
    var name: String
    var subtitle: String
    var description: String
    
    private var iconName: String
    var icon: Image {
        Image(iconName)
    }
    
    private var imageName: String
    var image: Image {
        Image(imageName)
    }
    
}
