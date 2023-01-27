//
//  MapView.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//
// This will be a MapView with all dots that would represent values from aurora JSON file.
//
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var provider: AuroraProvider
    
    var individualAuroraSpot: IndividualAuroraSpot
    var auroraList: [IndividualAuroraSpot]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        latitudinalMeters: 750,
        longitudinalMeters: 750)
    
    var body: some View {
        // look for MKPolyline, might be useful.
        // figure a way to represent a map and overlay it with a view
        Map(coordinateRegion: $region, annotationItems: auroraList ) { location in
            MapMarker(coordinate: CLLocationCoordinate2D(latitude: individualAuroraSpot.latitude, longitude: individualAuroraSpot.longitude), tint: .green)
        }
        .onAppear {
            withAnimation {
                region.center = CLLocationCoordinate2D(latitude: CLLocationDegrees(auroraList[0].latitude), longitude: CLLocationDegrees(auroraList[0].longitude))
                region.span = MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
                print(region.center)
            }
        }

    }
}


struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(individualAuroraSpot: AuroraLocationList.preview.auroraList[0], auroraList: AuroraLocationList.preview.auroraList)
            .environmentObject(AuroraProvider(client:
                                                AuroraClient(downloader: TestDownloader())))
    }
}
