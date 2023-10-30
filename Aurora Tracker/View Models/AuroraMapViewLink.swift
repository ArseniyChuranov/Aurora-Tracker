//
//  SheetAuroraInfo.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 3/27/23.
//

import SwiftUI

struct AuroraMapViewButton: View {
    
    @Binding var forecastTime: String
    @Binding var observationTime: String
    
    @State private var isSheetPresented = false
    
    var body: some View {
        AuroraMapView()
            .ignoresSafeArea()
        /*
         
        When used, for some reason renderer renders twice. Look into it.
         
         Display info other way
        
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
                    Text(forecastTime)
                        .font(.title2)
                    Text("Observation Time")
                    Text(observationTime)
                        .font(.title2)
                }
                .presentationDetents([.medium])
            }
        */
    }
}

struct AuroraMapViewButton_Previews: PreviewProvider {
    static var previews: some View {
        AuroraMapViewButton(forecastTime: .constant("time"), observationTime: .constant("timee"))
    }
}
