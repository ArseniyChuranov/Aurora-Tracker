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
                NavigationLink(destination:
                                SheetAuroraInfo(forecastTime: $infoList[0],
                                                observationTime: $infoList[1])) {
                    MainMenuButton()
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            await fetchAurora()
            
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

struct MainMenu_Previews: PreviewProvider {
    static var previews: some View {
        MainMenu(auroraList: .constant([IndividualAuroraSpot(longitude: 0,
                                                            latitude: 0,
                                                             aurora: 0)]))
    }
}
