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
    // @State private var newUpdatedList: [IndividualAuroraSpot] = []
    // private let downloader = TestDownloader()
    var newList: [IndividualAuroraSpot] = []
    var newPolygonList: [CLLocationCoordinate2D] = []
    //@State private var tintColor: Color
    
    
    //var individualAuroraSpot: IndividualAuroraSpot
    //var auroraList: [IndividualAuroraSpot]
    
   //var nonZeroList: [IndividualAuroraSpot]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        latitudinalMeters: 750,
        longitudinalMeters: 750)
    
    var body: some View {
        /*
        Map(coordinateRegion: $region, annotationItems: newList) { location in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
               
            }
        }
        */
        
        Map(coordinateRegion: $region, annotationItems: newList) { location in
            MapMarker(coordinate: CLLocationCoordinate2D(latitude: location.latitude,
                                                         longitude: location.longitude), tint: location.color)
        }
        .onAppear {
            withAnimation {
                region.center = CLLocationCoordinate2D(latitude: CLLocationDegrees(0), longitude: CLLocationDegrees(0))
                region.span = MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
            }
        }

    }
}

extension MapView {
    func nonEmptyList(incomeList: [IndividualAuroraSpot]) -> [IndividualAuroraSpot] {
        var newList: [IndividualAuroraSpot] = []
        print(provider.aurora.coordinates[0...10])
        for aurora in provider.aurora.coordinates {
            //print(provider.aurora.coordinates[0...10])
            if aurora.aurora != 0 {
                newList.append(aurora)
            }
        }
        print(newList[0])
        return newList
    }
    
    func PolyLineList(list: [IndividualAuroraSpot]) -> [CLLocationCoordinate2D] {
        var newList: [CLLocationCoordinate2D] = []
        // var secondList: [IndividualAuroraSpot] = []
        for aurora in list {
            if aurora.aurora == 1 {
                newList.append(CLLocationCoordinate2D(latitude: aurora.latitude, longitude: aurora.longitude))
            }
        }
        return newList
    }
    
}


/*
 
 switch aurora {
 case aurora.aurora == 1:
     newList.append(CLLocationCoordinate2D(latitude: aurora.latitude, longitude: aurora.longitude))
 default:
     secondList.append(aurora)
 }
 
*/


struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(newList: [IndividualAuroraSpot(longitude: 0, latitude: 0, aurora: 0)], newPolygonList: [])
            .environmentObject(AuroraProvider(client:
                                                AuroraClient(downloader: TestDownloader())))
    }
}

