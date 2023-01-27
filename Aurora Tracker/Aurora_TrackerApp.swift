//
//  Aurora_TrackerApp.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//

import SwiftUI

@main
struct Aurora_TrackerApp: App {
    @StateObject var auroraProvider = AuroraProvider()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auroraProvider)
        }
    }
}
