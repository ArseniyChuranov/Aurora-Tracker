//
//  ContentView.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//

import SwiftUI
import MapKit
import QuartzCore // ?????

struct ContentView: View {
    
    @EnvironmentObject var provider: AuroraProvider
    private let downloader = TestDownloader()
    private let client = AuroraClient()
    @State private var newList: [IndividualAuroraSpot] = []
    @State private var newPolygonList: [CLLocationCoordinate2D] = []
    
    @State private var newColorList: [UInt32] = []
    
    @State private var error: AuroraError?
    @State private var hasError = false
    
    let coordinateCalculate = CoordinateCalculations()

    var body: some View {
        MainMenu(auroraList: $newList)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
