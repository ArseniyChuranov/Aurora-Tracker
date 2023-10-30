//
//  CoordinateFinder.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 5/25/23.
//

/*

 This class is responsible for determining and finding coordinates
    
 Every action that has to do with determining tile coordinates on the map and getting info from Aurora list,
 will be perfored here.
 
 Each function will have decription and commentaries.
 
 */

import Foundation

class CoordinateFinder {
    
    // This method converts globe coordinates to mercator ratios, needs resolution to create a more specific point.
    // This function takes Geo coordinates and apply Mercator projection to them.
    
    // not implemented?
    
    func geoLatLonToMercatorSecond(inputLatitude: Double, inputLongitude: Double, resolution: Int) -> (outputLatitude: Double, outputLongitude: Double) {
        
        //
        let mapSide = Double(resolution)
        
        let outputLongitude = inputLongitude * (mapSide / 360)
        
        
        let latRad = inputLatitude * Double.pi / 180
        
        let mercN = log(tan((Double.pi / 4) + (latRad / 2)))
        let outputLatitude = (mapSide / 2) - (mapSide * mercN / (2 * Double.pi))
        
        
        let roundedLongitude = Double(round(outputLongitude))
        let roundedLatitude = Double(round(outputLatitude))
        
        return (roundedLatitude, roundedLongitude)
    }
    
    
    // This function allows to calculate all corner values of a tile, by providing requested Tile number.

    
    func tileToCoordinate(_ tileX: Int, _ tileY: Int, zoom: Int) -> ([Double]) {

        // List with coordinates of a corner in such order: bottomLeftLat, bottomLeftLon, bottomRightLon, topLeftLat
        var outputList: [Double] = []
        
        // Resolution of a whole map in pixels, for requested zoom level.
        
        let res: Double = pow(2, Double(zoom))

        
        let bottomLeftLat = atan( sinh (.pi - (Double(tileY) / res) * 2 * Double.pi)) * (180.0 / .pi)
        let bottomLeftLon = (Double(tileX) / res) * 360.0
        let bottomRightLon = (Double(tileX + 1) / res) * 360.0
        let topLeftLat = atan( sinh (.pi - (Double(tileY + 1) / res) * 2 * Double.pi)) * (180.0 / .pi)
        
        // Add each value to the list in specific order.
        
        outputList.append(bottomLeftLat)
        outputList.append(bottomLeftLon)
        outputList.append(bottomRightLon)
        outputList.append(topLeftLat)
        
        return outputList
    }
    
    // This function cycles through a list to find each value that fits within the requested values
    
    func findCoordinatesForTile(_ inputList: [IndividualAuroraSpot], tileBordersList: [Double]) -> [IndividualAuroraSpot] {
        
        // Output list with next whole values that are outside of tileBorderList values
        
        var outputList: [IndividualAuroraSpot] = []
        
        // Actual corner coordinates
        
        let topLatitude = tileBordersList[0]
        let bottomLatitude = tileBordersList[3]
        let maxLongitude = tileBordersList[2]
        let minLongitude = tileBordersList[1]
        
        // Outer boundaries for latitude and longitude describing a larger square where actual coordinates fit
        
        let celingLatitudeValue = topLatitude.rounded(.up)
        let floorLatitudeValue = bottomLatitude.rounded(.down)
        let startLongitudeValue = minLongitude.rounded(.down)
        let finishLongitudeValue = maxLongitude.rounded(.up)
        
        // Cycle through list and append anything that fits inside tile.
        
        /*
         
         Find a way to optimize this method, so far it takes 2 conditions to add an item to my list. This seems ok,
            but could be taking quite some time.
         
         */
        
        for aurora in inputList {
            if aurora.longitude >= startLongitudeValue && aurora.longitude <= finishLongitudeValue {
                if aurora.latitude >= floorLatitudeValue && aurora.latitude <= celingLatitudeValue {
                    outputList.append(aurora)
                }
            }
        }
        
        return outputList
    }
    
    
    // find dimensions of a list
    
    
    func findSquareDimensions(_ inputList: [IndividualAuroraSpot]) -> (height: Int, width: Int) {
        
        // dimensions of a tile
        
        var height = 0
        var width = 0
        
        // Count of similar values will provide dimensions of a tile.
        
        let widthCount = inputList[0].latitude
        let heightCount = inputList[0].longitude
        
        // !!! In future account for 2 values only. !!!
        
        for item in inputList {
            
            // same latitude = width
            
            if item.latitude == widthCount {
                width = width + 1
            }
            
            // same longitude = height
            
            if item.longitude == heightCount {
                height = height + 1
            }
        }
        
        if height < 2 || width < 2 {
            print("Calculation error! List of coordinates fot tile is smaller than actual tile.")
            print()
        }
        
        return (height, width)     
    }
    
    
    // This function calculates corner values based on outer edges of a tileList
    
    
    func calculateCornerAuroraValues(inputAuroraList: [IndividualAuroraSpot],
                                     tileBordersList: [Double],
                                     height: Int,
                                     width: Int) -> [IndividualAuroraSpot] {
        
        var outputList = inputAuroraList
        
        // for each border value calculate aurora value
        
        var bottomLeftAuroraValue = 0
        var topLeftAuroraValue = 0
        var bottomRightAuroraValue = 0
        var topRightAuroraValue = 0
        
        // Actual corner coordinates
        
        let topLatitude = tileBordersList[0]
        let bottomLatitude = tileBordersList[3]
        let maxLongitude = tileBordersList[2]
        let minLongitude = tileBordersList[1]
        
        // diagonal value can be from 0 to Sqrt() (1.4...), aurora value can be only 0...1 * difference between values.
        
        let diagonalTax = sqrt(2)
        
        // !!! THIS CAN BE FURTHER COMPRESSED AND OPTIMIZED !!! //
        
        // Calculations for Bottom Left corner
        
        let bottomLeftDiagonalLat = abs(bottomLatitude - bottomLatitude.rounded(.down))
        let bottomLeftDiagonalLon = abs(minLongitude - minLongitude.rounded(.down))
        let bottomLeftDiagonalValue = sqrt(pow(bottomLeftDiagonalLat, 2) + pow(bottomLeftDiagonalLon, 2)) / diagonalTax
        
        // Calculations for Top Left corner
        
        let topLeftDiagonalLat = abs(topLatitude.rounded(.up) - topLatitude)
        let topLeftDiagonalLon = bottomLeftDiagonalLon // they are same
        let topLeftDiagonalValue = sqrt(pow(topLeftDiagonalLat, 2) + pow(topLeftDiagonalLon, 2)) / diagonalTax
        
        // Calculations for Bottom Right corner
        
        let bottomRightDiagonalLat = bottomLeftDiagonalLat // bottom latitude
        let bottomRightDiagonalLon = abs(maxLongitude.rounded(.up) - maxLongitude)
        let bottomRightDiagonalValue = sqrt(pow(bottomRightDiagonalLat, 2) + pow(bottomRightDiagonalLon, 2)) / diagonalTax
        
        // Calculations for Top Right corner
        
        let topRightDiagonalLat = topLeftDiagonalLat
        let topRightDiagonalLon = bottomRightDiagonalLon
        let topRightDiagonalValue = sqrt(pow(topRightDiagonalLat, 2) + pow(topRightDiagonalLon, 2)) / diagonalTax
        
        // Findind other corner value to determine difference between 2 values, to calculate output.
        
        /*
         
         in theory a way to find an opposite corner would be to find difference between height + width.
         
         index = 0
         lastIndex = last element in the list
         
         for bottom left corner that would be = (height + 1)
         for top left corner that would be = (height + height - 2)
         for bottom right corner that would be = (lastIndex - (2 * height) + 2) // rethink this one maybe?
         
                    find a method that would work for every single case
         
            bottom right = (height * width) - 1 - height || TRY THIS """(height * width) - (2 * height) + 1"""
         for top right corner that would be = (lastIndex - height - 1)
         
         so for list of 4 items that would equate to:
            2 + 1 = 3
            2 + 2 - 2 = 2
            3 - (2 * 2) + 2 = 1 // new method  = (())
            3 - 2 - 1 = 0
         
         calculate for 6 item list. height = 3, width = 2
         
            3 + 1 = 4
            3 + 3 - 2 = 4
            5 - (2 * 3) + 2 = 1 => this should be 2 instead of 1 // alternative method =  (3 * 2) - 1 - 3 = 2  || TRY THIS
            5 - 3 - 1 = 2
         
         oh. That might explain it...
         
         calculate for 9 item list, height = 3, width = 3
         
            3 + 1 = 4
            3 + 3 - 2 = 4
            ((3 - 2) * 3) + 1 = 4 // diff method, old method: (3 * 3) - 1 - 3 = 5 // dont change methods**
            8 - 3 - 1 = 4
         
         calculate for 12 item list, height = 4, width = 3
         
            4 + 1 = 5
            4 + 4 - 2 = 6
            ((4 - 2) * 3) - 1 = 5
            11 - 4 - 1 = 6
         
         so far everything seems to be correct.
            
         
         
         
         */
        
        
        return outputList
    }
    
}
