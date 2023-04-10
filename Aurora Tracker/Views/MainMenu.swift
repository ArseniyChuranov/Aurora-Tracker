//
//  MainMenu.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 3/18/23.
//

import SwiftUI
import MapKit

struct MainMenu: View {
    
    @Binding var auroraList: [IndividualAuroraSpot]
    @EnvironmentObject var provider: AuroraProvider
    @EnvironmentObject var eventModel: EventModel
    
    @State private var error: AuroraError?
    @State private var hasError = false
    
    @State private var infoList: [String] = ["0", "1"]
    
    @State private var isSheetPresented = false
    
    var body: some View {
        
        /*
         
         Create a menu view, with a button that will navigate to the map.
         
         */
        
        VStack {
            NavigationView {
                List {
                    NavigationLink(destination:
                                    SheetAuroraInfo(forecastTime: $infoList[0],
                                                    observationTime: $infoList[1])) {
                        MainMenuButton()
                            .foregroundColor(.white)
                        
                        
                    }
                    NavigationLink(destination: EventsList()) {
                        EventsButton()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button (action: {
                            isSheetPresented = true
                        }) {
                            Image(systemName: "info.circle")
                        }
                    }
                }
                .sheet(isPresented: $isSheetPresented) {
                    // input info about current aurora.
                    
                    // when used, map creates double layers of tiles, fix that.
                    VStack {
                        Text("Forecast Time")
                        Text(provider.aurora.forecastTime)
                            .font(.title2)
                        Text("Observation Time")
                        Text(provider.aurora.observationTime)
                            .font(.title2)
                    }
                    .presentationDetents([.medium])
                    .padding()
                }
            }
            
        }
        .task {
            // This async function calls for actual data, disable if needed to work with sample data.
            // Last updates sample data will be written to aurora.json file in documents directory.
            
            await fetchAurora()
            
            //
            
            infoList[0] = provider.aurora.forecastTime
            infoList[1] = provider.aurora.observationTime
 
        }
    }
}


extension MainMenu {
    
    func fetchAurora() async {
        do {
            
//            Actual Data from Database online

            try await provider.fetchAurora()
            
//             Sample Data
            
//            let downloader = TestDownloader()
//            let client = AuroraClient(downloader: downloader)
//            let aurora = try await client.aurora
//            newList = aurora.coordinates

            
        } catch {
            self.error = error as? AuroraError ?? .unexpectedError(error: error)
            self.hasError = true
        }
    }
}


/*
 struct MainMenu_Previews: PreviewProvider {
 // doesn't work
 static var auroraPreview = IndividualAuroraSpot.preview
 
 static var previews: some View {
 MainMenu(auroraList: .constant(auroraPreview))
 .environmentObject(EventModel())
 .environmentObject(AuroraProvider(client: AuroraClient(downloader: TestDownloader())))
 .environment(\.colorScheme, .dark)
 }
 }
 */
