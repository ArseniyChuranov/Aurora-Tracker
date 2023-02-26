//
//  AuroraTileOverlay.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 2/10/23.
//

import Foundation
import MapKit

class AuroraMapOverlay: MKTileOverlay {
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        
        // For now this method looks for a custom created folder that contains all maps for several layers.
        // Dad suggested to render and create pictures individually, it's a great idea. I will work on it next.
        
        /*
         
         Individual render plan:
            1. Calculate all visible tiles (center tile + Surrounding tiles)
                minimum visible tile zoom level is 3-4 as I figured, keep that in mind when creating a method for calculating tiles.
            2. Calculating a list of all coordinates in each tile, including extra that will represent corners, or creating a one based on corner coordinates.
            3. Drawing a gradient for each coordinate rectangle.
            4. Creating a picture, and passing it to the function.
         
         Considerations:
            Method will always draw only certain amount of pixels, if max visible amount if tiles is always 9, then its (256 * 3)^2 = 589 824 pixels.
                I would need to check maximum visible amount to calculate precise number, and find a way to optimize it.
            Storing some pictures to save on redrawing especially dense tiles (zoom level 3-5 where there are a lot of coordinates)
                        
         */
        
        let fileDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        var tilePath = fileDirectory.appendingPathComponent("Tiles")
   
        // Get to the directory, and check if path exists with path info
        
        func tileExists(for tileLocalPath: MKTileOverlayPath) -> Bool {
   
            let existingPath = tilePath?.appendingPathComponent("\(tileLocalPath.z)/\(tileLocalPath.x)/\(tileLocalPath.y).png")

            let filePath = existingPath!.path()
            let fileManager = FileManager.default
            return fileManager.fileExists(atPath: filePath)

        }
        
        // Returns a tile only if it exists.
        
        if tileExists(for: path) {
            let existingPath = tilePath?.appendingPathComponent("\(path.z)/\(path.x)/\(path.y).png") // was png
            tilePath = existingPath!
        }
        

        
        return tilePath!
    }
}
