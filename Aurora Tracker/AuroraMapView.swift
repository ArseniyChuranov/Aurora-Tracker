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
    func addMapOverlay(to view: MKMapView) {
        if !view.overlays.isEmpty {
            view.removeOverlays(view.overlays)
        }
    }
}


class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let overlay = AuroraMapOverlay()
        
        
        overlay.canReplaceMapContent = false
        overlay.minimumZ = 1
        overlay.maximumZ = 4
        
        //mapView.addOverlay(overlay, level: .aboveLabels)
        
        let renderer = MKTileOverlayRenderer(tileOverlay: overlay)
       
        // Add functionality that would allow to change alpha value.
        
        renderer.alpha = 0.35 // was 0.25
        
        return renderer

    }
}

