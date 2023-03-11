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
    @Binding var auroraList: [IndividualAuroraSpot] // get info and see if that can be passed
    
    

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
        
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.delegate = mapViewDelegate
        uiView.translatesAutoresizingMaskIntoConstraints = false
        // passing info here won't give me info i need.
        uiView.addOverlay(AuroraMapOverlay(), level: .aboveLabels)
        //print(uiView)
    }
}

private extension AuroraMapView {
    func addMapOverlay(to view: MKMapView) {
        /*
        if !view.overlays.isEmpty {
            view.removeOverlays(view.overlays)
        }
         */
    }
}


class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    // maybe load stuff in the delegate?
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let overlay = AuroraMapOverlay()
      
        // this method gets info that passes to the overlay function and changes it. i can use this info and change this function to get binding info. If i can.
        
        overlay.canReplaceMapContent = false
        overlay.minimumZ = 1
        //overlay.maximumZ = 4
        
        // function starts once.
        
        //mapView.addOverlay(overlay, level: .aboveLabels)
        
        let renderer = MKTileOverlayRenderer(tileOverlay: overlay) // Look into MKTileOverlayRenderer
       
        // Add functionality that would allow to change alpha value.
        
        renderer.alpha = 0.35 // was 0.25
        
        return renderer

    }
}

