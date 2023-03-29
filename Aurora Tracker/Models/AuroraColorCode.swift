//
//  AuroraColorCode.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/27/23.
//

import SwiftUI
// create a colorful Scale that will represent Auroras pretty accurate.
// not implemented now, later might be useful.
extension IndividualAuroraSpot {
    var color: Color {
        switch aurora {
        case 0..<10:
            return .green
        case 10..<15:
            return .yellow
        case 15..<20:
            return .orange
        case 20..<25:
            return .red
        case 25..<Double.greatestFiniteMagnitude:
            return .init(red: 0.8, green: 0.2, blue: 0.7)
        default:
            return .gray
        }
    }
}
