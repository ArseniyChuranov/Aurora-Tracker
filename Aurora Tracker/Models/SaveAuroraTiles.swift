//
//  SaveAuroraTiles.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 2/10/23.
//

import Foundation
import CoreGraphics
import CoreImage
import UIKit
import MapKit


class SaveAuroraTiles: ObservableObject {
    
    @Published var mapTileImage: [CGImage] = []
    
    /*
     
     Plan is simple in theory:
        1. Get bitmap info to generate an image
        2. Break down image into tilesets, uwing a method that will "cut" picture into 256x256 tiles.
        3. create folder for each zoom level and for each X coordinate tilesets based on resolution of a picture
        4. create tiles and place then into appropriate folders.
     
     */
    
    // Create a "Tiles" filder in documents direcroty where all tiles will be placed
    
    func createTileDirectory() {
        
        let documentDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let dirPathTiles = documentDirectory.appendingPathComponent("Tiles")
        
        if !FileManager.default.fileExists(atPath: dirPathTiles!.path()) {
            
            // if directory doesnt exist, create new.
            
            do {
                try FileManager.default.createDirectory(atPath: dirPathTiles!.path() , withIntermediateDirectories: true, attributes: nil)
    
            } catch {
                print(error.localizedDescription)
            }
        }
  
    }
    
    // create new directories, use same system as used for tileRenderer.
    
    func createDirectoriesForTiles(zoomLevel: Int) -> (z: URL?, x: [URL?]) {
        
        let fileDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let tilePath = fileDirectory.appendingPathComponent("Tiles")
        
        // Name of a zoom folder would be a zoom level Int
        
        let zTilesPath = tilePath!.appendingPathComponent("\(zoomLevel)")
        var xTilesPathList: [URL?] = []
        
        // all tiles path also function as a path to each
        
        if FileManager.default.fileExists(atPath: tilePath!.path()) {
            
            // directory exists, create directory for a Zoom level with correct name
            
            do {
                try FileManager.default.createDirectory(atPath: zTilesPath.path(), withIntermediateDirectories: true)
            } catch {
                print(error.localizedDescription)
            }
            
            // after Zoom level directory is created, directory for X will be created
            // cycle and create all needed folders based on zoom.
            
            if zoomLevel == 1 {
                
                // create an url list
                
                for item in 0...1 {
                    
                    let xTilesPath = zTilesPath.appendingPathComponent("\(item)") // x axis, "for" cycle needed.
                    
                    do {
                        try FileManager.default.createDirectory(atPath: xTilesPath.path(), withIntermediateDirectories: true)
                        xTilesPathList.append(xTilesPath)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                
            } else {
                
                let tileAmount = Int(pow(2, Double(zoomLevel)))
                
                for item in 0...(tileAmount - 1) {
                    let xTilesPath = zTilesPath.appendingPathComponent("\(item)") // x axis, "for" cycle needed.
                    
                    do {
                        try FileManager.default.createDirectory(atPath: xTilesPath.path(), withIntermediateDirectories: true)
                        xTilesPathList.append(xTilesPath)
                    } catch {
                        print(error.localizedDescription)
                    }
                }

            }
  
        }
        
        return(zTilesPath, xTilesPathList)
    }
    
    
    func generateGridTilePicture(inputList: [UInt32], resolution: Int, zoomLevel: Int) -> Void {
        
        // Create "Tiles" folder if needed.
        
        createTileDirectory()
        
        // Create folders for tiles based on zoomLevel^2
        
        let tileAmount = Int(pow(2, Double(zoomLevel)))
        
        let filesPath = createDirectoriesForTiles(zoomLevel: zoomLevel)
 
        let xTileURL = filesPath.x // list

        let colorList = inputList
        
     
        var tileSetList: [[UInt32]] = []
        var flippedSetList: [[UInt32]] = []
        
        // Create empty lists to later fill them with tile information.
        
        let totalTilesCount = Int(pow(2, Double(zoomLevel * 2)))
        
        for _ in 0...(totalTilesCount-1) {
            let emptyList: [UInt32] = []
            tileSetList.append(emptyList)
            //flippedSetList.append(emptyList)
            
        }


        // Break down a picture into 256x256 tiles.
        
        var listIndex = 0
  
        var indexAxisX = 0
        var indexAxisY = 0
        
        var tileIndexYCount = 0
        var tileIndexXCount = 0
        
        for item in colorList { // should cycle through whole list

            
            /*
             
             method for breaking down one tile into an appropriate amount of tiles
             example - 512
             resolution of 512 will yield into 2 of 256 x 256 tiles, number of 1 line of tiles can be calculated if we divide resolution by 256,
             same number will apply to amount of tiles per row
             
             each list will contain data based on index of 256, with first having elements of index 0-255, and 256-511,
             same breaking down will be applied to the y axis. i cn create x and y indexes and cycle through them and switch lists based on index value
             for now i will simplify to use for 512 tiles
             
             direction of list goes from bottom to top, left to right
             
             so the adresses will be filled in order of lardgestYValue.0, largestYValue - 1.0 .... 0.lasrgestXValue - 1, 0.LargestXValue
             for tiles of 512 it would be 0.1, 0.0, 1.1, 1.0.
             list would look like this   [[0], [1], [2], [3]]
             
             
             
             cycle index starts from 0 and goes up to tileNumbers - 1
             
             for each new axis index change i can add a new tile index in theory, or equate it
             
             */
            
            // this loop should create tilesNumber amount of sets and then can cycle through to create a tileSet
            // check for index that goes up to a max value, when it is resolution - 1 = zero it
            // have a condition that will first check x, then y value, and then calculate where the list should be

            /*
             
             items will be added for the whole duration of cycle, so i would need to make sure i wont overrun with indexes and logic
             
             if indexAxisY == resultion, we are on top of grid,
             else if indexAxisY % 256 == 0, it means we can add one point
   
             start with only x axis, creating 2 lists, split in half
             
             */
            
            if indexAxisY == resolution { // if top of list
                indexAxisX = indexAxisX + 1
                tileIndexXCount = tileIndexXCount + 1
                indexAxisY = 0
                tileIndexYCount = 0
                listIndex = listIndex - (tileAmount - 1)
            }
            
            if tileIndexYCount == 256 { //
                tileIndexYCount = 0
                listIndex = listIndex + 1
            }

            if tileIndexXCount == 256 {
                
                // do it for each 256
                // each list should have 65536 items
               
                listIndex = listIndex + tileAmount
                indexAxisX = indexAxisX + 1
                tileIndexXCount = 0
            }

            tileSetList[listIndex].append(item)
            
            indexAxisY = indexAxisY + 1
            tileIndexYCount = tileIndexYCount + 1
        }
        
        // Due to my laziness I decided to rotate each tile here, will be fixed later.
        
        func rotateImage(inputImage: [UInt32]) -> [UInt32] {
            var outputImage: [UInt32] = []
            
            // rotating image means flip 90 to the right.
            // fins square root of a tile, that will give a side amount
            
            let listLen: Double = Double(inputImage.count)
            let sideLen = sqrt(listLen)
            
            var rowList: [UInt32] = []
            var itemIndex = 0
            
            // each side is equals to amount of elements i have per row, and index for next row position
            
            for column in 0...(Int(sideLen) - 1) {
                // cycle through each side, creating a row
                // secont loop will come here
                
                for _ in 0...(Int(sideLen) - 1) {
                    // collect items per each row
                    rowList.append(inputImage[itemIndex])
                    itemIndex = itemIndex + Int(sideLen)
                    
                }
                
                itemIndex = 1 + column
                outputImage.append(contentsOf: rowList)
                
                rowList = []
            }
            return outputImage
        }
      
        var xTileIndex = 0
        var yTileName: Int = 0

        // Rotate images.
        
        for list in tileSetList {
            let product = rotateImage(inputImage: list)
            
            flippedSetList.append(product)
        }
        
        // Create a png butmap for each picture
        
        for tile in 0...(totalTilesCount - 1) {
            
            let cgImg = flippedSetList[tile].withUnsafeMutableBytes { (ptr) in
                let ctx = CGContext(data: ptr.baseAddress,
                                    width: 256,
                                    height: 256,
                                    bitsPerComponent: 8,
                                    bytesPerRow: 4 * 256,
                                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue + CGImageAlphaInfo.premultipliedLast.rawValue)!  // CGImageAlphaInfo.premultipliedFirst.rawValue) // & CGBitmapInfo.alphaInfoMask.rawValue
                
                return ctx.makeImage()!
            }
            
            let uiImage = UIImage(cgImage: cgImg)

            // Create an URL for an image.
            
            var fileUrl = xTileURL[xTileIndex]
            fileUrl = fileUrl?.appendingPathComponent("\(yTileName)" + ".png")

            // Create image.
            
            if let newImage = uiImage.pngData() {
                try? newImage.write(to: fileUrl!)
            }
            
            // Update indexes
            
            yTileName = yTileName + 1
            
            if yTileName == tileAmount {
                xTileIndex = xTileIndex + 1
                yTileName = 0
            }
        }
    }
}


// Previous and not implemented methods.

/*
 
 if indexAxisY == resolution { // if index is on the top of grid,
     indexAxisY = 1
     indexAxisX = indexAxisX + 1
     listIndex = startYIndex
     // start a list index from a first valut it was
 } else if indexAxisY % 256 == 0 && indexAxisY != 0 { // if index divides by one tile number, up the new
     // tileAdressY = newZoomLevel - (indexAxisY / 256) // get an adress for a tile to fill on Y axis

     
     listIndex = listIndex + 1 // we come to the next list
     
     // change the address here:
     
     // figure a way to always calculate it
     // listIndex = ((newZoomLevel - 1) - tileAdressY) - (tileAdressX - newZoomLevel - 1)
     
 }
 
 
 if indexAxisX % 256 == 0 && indexAxisX != 0{
     // we are at new tile
     
     
     // change it so it starts  different, implement row count
     listIndex = rowCount + newZoomLevel // ? meaning we jump over the next row of tiles
     rowCount = newZoomLevel
     startYIndex = listIndex
     indexAxisX = 0
     
     // should be a new row information
 
 }
 
 
 
 
 /*
  
  else if indexAxisX % 256 == 0 && indexAxisX != 0 {
     // same for X
     print("func 2")
     tileAdressX = newZoomLevel - (indexAxisX / 256)
 } else {
     // can fill in results
     
     
 }
  
  */
 

 
 
 // i would need a system that will create a list index based on coordinates
 /*
  
  for example: 0 on X and 0 on Y would be top left corner.
  first item in list eill have lowest x and hoghest y value, highest values are going to be tiles per side - 1
  
  */
 
 
 // assign value here to a list
 
 //print(listIndex)
 
 
 
 
 
 
 
 /*
 if listIndex == (tilesNumber - 1) { // if we are at last tile
     tileSetList[listIndex].append(item)
     listIndex = 0
 } else {
     tileSetList[listIndex].append(item)
     listIndex = listIndex + 1
     
 }
  */
 
 
 
 
 
 
 
 
 if indexAxisX % 256 == 0 && indexAxisX != 0{
     // we are at new tile on X axis,
     
     // row count will pe updated here
     
     // if we are here, we should have all Y axis tiles filled with 65536 items each
     
     rowCount = rowCount + newZoomLevel // row count is previous plus zoom level, thats a start of a new index
     
     
     // last iteration will still go from here. last item will be out of list bound
     print(indexAxisX) // should be printed only once.
     
     listIndex = rowCount
     startYIndex = listIndex // is where is starts from bottom for y axis
     //indexAxisX = indexAxisX + 1
     //indexAxisX = 0

 }
 
 if indexAxisY == resolution { // if top of grid
     // if index is on the top of grid, reatart y index, append 1 to xindex, equate list index to start from bottom
     indexAxisY = 0
     indexAxisX = indexAxisX + 1
     listIndex = startYIndex
     
     tileSetList[listIndex].append(item)

 } else if indexAxisY % 256 == 0 && indexAxisX != 0 { // if new tile
     listIndex = listIndex + 1 // we come to the next list
     // after this i should have 65536 items in each list.
     tileSetList[listIndex].append(item)
     
 } else {
     tileSetList[listIndex].append(item)
     
 }

 
 
 
 
 
 
 if indexAxisY == resolution { // if top of list
     indexAxisX = indexAxisX + 1
     indexAxisY = 0
     listIndex = listIndex - 1
 }
 
 if indexAxisY == 256 { // halfway through one cycle?
     listIndex = listIndex + 1
 }
 
 // when indexAxisX == 256, it means we are
 
 if indexAxisX == 256 {
     // first list should have 131,072 items
     
     // now first list is 512 items short
     listIndex = listIndex + 2
     indexAxisX = indexAxisX + 1
 }

 tileSetList[listIndex].append(item)
 
 
 indexAxisY = indexAxisY + 1
 
 
 
 
 
 
 
 */
