//
//  ContentView.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var provider: AuroraProvider
    private let downloader = TestDownloader()
    private let client = AuroraClient()
    
    @State private var error: AuroraError?
    @State private var hasError = false
    
    let staticData: Aurora = Aurora(observationTime: "Current time",
                                    forecastTime: "Future time",
                                    coordinates: [IndividualAuroraSpot(longitude: 0,
                                                                       latitude: 0,
                                                                       aurora: 0)])


    var body: some View {
        VStack {
            
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text(provider.aurora.observationTime)
            Text(provider.aurora.forecastTime)
            HStack {
                Text(String(provider.aurora.coordinates[0].latitude))
                Text(String(provider.aurora.coordinates[0].longitude))
                Text(String(provider.aurora.coordinates[0].aurora))
            }
        }
        .padding()
        .task {
            await fetchAurora()
        }
    }
}

extension ContentView {
    func fetchAurora() async {
        do {
            try await provider.fetchAurora()
        } catch {
            self.error = error as? AuroraError ?? .unexpectedError(error: error)
            self.hasError = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuroraProvider(client:
                                                AuroraClient(downloader: TestDownloader())))
    }
}
