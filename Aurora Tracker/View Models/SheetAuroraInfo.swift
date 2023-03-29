//
//  SheetAuroraInfo.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 3/27/23.
//

import SwiftUI

struct SheetAuroraInfo: View {
    
    @Binding var forecastTime: String
    @Binding var observationTime: String
    
    @State private var isSheetPresented = false
    
    var body: some View {
        AuroraMapView()
            .ignoresSafeArea()
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
    }
}

struct SheetAuroraInfo_Previews: PreviewProvider {
    static var previews: some View {
        SheetAuroraInfo(forecastTime: .constant("time"), observationTime: .constant("timee"))
    }
}
