//
//  AuroraMapView.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/30/23.
//

import MapKit
import UIKit
import SwiftUI
import Foundation

struct AuroraMapView: UIViewRepresentable {
    
    let mapViewDelegate = MapViewDelegate()
     // @Binding var auroraList: [IndividualAuroraSpot] // get info and see if that can be passed
    let annotations: [MKAnnotation] = []
    
    

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
        
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.delegate = mapViewDelegate
        uiView.translatesAutoresizingMaskIntoConstraints = false
        uiView.addOverlay(AuroraMapOverlay(), level: .aboveLabels)

    }
}

private extension AuroraMapView {
    func dropPins() -> [MKAnnotation] {
        let pinsNum = 85 //  171
        var startLatitude = 0 // -85
        
        var annotationList: [MKAnnotation] = []
        
        for _ in 1...pinsNum {
            let coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: CLLocationDegrees(startLatitude), longitude: 180)
            
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            pin.title = String(coordinates.latitude)
            pin.subtitle = String(coordinates.longitude)
            
            startLatitude += 1
            
            
            annotationList.append(pin)
        }

        return annotationList
    }

    
    func addMapOverlay(to view: MKMapView) {
        if !view.overlays.isEmpty {
            view.removeOverlays(view.overlays)
        }
    }
}


class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    /*
    func mapView(_ mapView: MKMapView, didDeselect annotation: MKAnnotation) {
        print(annotation.coordinate)
        let title = annotation.title ?? "Not Found"
        print(title!)
    }
     */
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let overlay = AuroraMapOverlay()
      
        
        overlay.canReplaceMapContent = true // later change to false
        overlay.minimumZ = 1
        //overlay.maximumZ = 4
        
        //Every time i use info feature, this function reloads. Learn hot to stop processes.

        
        let renderer = MKTileOverlayRenderer(tileOverlay: overlay) // Look into MKTileOverlayRenderer
       
        // Add functionality that would allow to change alpha value.
        
        // alpha value for renderer.
        
        renderer.alpha = 1 // 0.75 // was 0.25 // recent 0.35
        
        return renderer

    }
}

