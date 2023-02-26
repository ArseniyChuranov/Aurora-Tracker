//
//  AuroraCoordinateRectangle.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 2/5/23.
//

import Foundation

struct AuroraCoordinateRectangle: Identifiable {
    var id: UUID
    // Rectangle Coordinates and Aurora values.
    
    // Coordinates will represent bottom left corner for Latitude and Longitude, bottom right longitude and top left corner as latitude value, this will give enough information to form a rectangle and calculate its sides.
    // Aurora values will be in different corners and will be needed for calculating gradient that will fill values between coordinates.
    
    /*
     
     Example:
     
     AuroraCoordinateValie: (coorinateList: [0.0, 0.0, 4.0, 4.0], auroraList: [1.0, 1.0, 2.0, 2.0])
     
     Function for gradient will take these values and fill
     
     1.0 0.0 0.0 0.0 1.0     1.0  1.0  1.0  1.0  1.0      Values that will be filled
     0.0 0.0 0.0 0.0 0.0     1.25 1.25 1.25 1.25 1.25     1.25 1.25 1.25 1.25
     0.0 0.0 0.0 0.0 0.0 =>  1.5  1.5  1.5  1.5  1.5  =>  1.5  1.5  1.5  1.5
     0.0 0.0 0.0 0.0 0.0     1.75 1.75 1.75 1.75 1.75     1.75 1.75 1.75 1.75
     2.0 0.0 0.0 0.0 2.0     2.0  2.0  2.0  2.0  2.0      2.0  2.0  2.0  2.0
     
     */
    
    var coordinateList: [Double] // [Bottom Left Corner Latitude, Bottom left Corner Longitude, Bottom Right Corner, Top Left Corner]]
    var auroraList: [Double] // [Aurora Bottom Left Corner, Aurora Bottom Right Corner, Aurora Top Left Corner, Aurora Top Right Corner]
}
