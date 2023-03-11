//
//  AuroraTileOverlay.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 2/10/23.
//

import Foundation
import MapKit
import SwiftUI

class AuroraMapOverlay: MKTileOverlay {
    
    let coordinateCalculate = CoordinateCalculations()
    
    private var error: AuroraError?
    private var hasError = false
    private var newList: [IndividualAuroraSpot] = []
    private var maxAurora: Double = 0
    
    // create a load function and see if it helps? get info from local fileData.
    
    private var loadedData = false
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        
        
        // loads a lot of tiles, for each would need to create a drawing function.
        // since function provides info for a tile, i can just get each tile's info and cycle ith through a function ang get info.
        
        // Current function returns an URL and not a picture, would make sense for temp create url with picture,
        // and get appropriate naming for each tile.
        // but later would make sense to shorten functionality to return a picture. look more into this functionality of MKTileOverlay
        
        // For now this method looks for a custom created folder that contains all maps for several layers.
        // Dad suggested to render and create pictures individually, it's a great idea. I will work on it next.
        
        // Look into loadTile and possibly override it to be able to perform async creation of new tiles for specific coordinates range
        /*
         
         Individual render plan:
         1. Calculate all visible tiles (center tile + Surrounding tiles)
         minimum visible tile zoom level is 3-4 as I figured, keep that in mind when creating a method for calculating tiles.
         2. Calculating a list of all coordinates in each tile, including extra that will represent corners, or creating a one based on corner coordinates.
         3. Drawing a gradient for each coordinate rectangle.
         4. Creating a picture, and passing it to the function.
         
         Considerations:
         Method will always draw only certain amount of pixels,
         if max visible amount if tiles is always 9, then its (256 * 3)^2 = 589 824 pixels. // wrong
         I would need to check maximum visible amount to calculate precise number, and find a way to optimize it.
         Storing some pictures to save on redrawing especially dense tiles (zoom level 3-5 where there are a lot of coordinates)
         
         */
        
        // Optimize this mess when progress is made.
        
        /*
         
         Function logic
         
         1. Based on path provided by request, calculate coordinates it should represent
         2. Find coordinates and append / create unique to a list
         3. Create rectangles for each, append to a list
         4. Create gradient for each rectangle, recalculate for individual tile correct coordinates on grid
         5. Create a bitmap picture and save it to a file temporarely
         6. link for ech path in that file and update every single request
         
         */
        
        // temp function to create a bitmap and to transform into a colored picture
        
        let fileDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let tilePath = fileDirectory.appendingPathComponent("Tiles")
        let stringPath = (tilePath?.path)! + "/"
        var numbersOfItems = 0
        
        // simple check here for amount of tiles, and if number of them is larger than <Figure out a number>, delete all/
        
        do {
            numbersOfItems = try FileManager.default.contentsOfDirectory(atPath: stringPath).count

        } catch let error {
            print(error.localizedDescription)
        }
        
        if numbersOfItems > 100 {
            do {
                let pictures = try FileManager.default.contentsOfDirectory(at: tilePath!,
                                                                           includingPropertiesForKeys: nil,
                                                                           options: .skipsHiddenFiles)


                for url in pictures {
                    try FileManager.default.removeItem(at: url)
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        }
        

        // loaded data will also be used fror a one tine implemintation, like parsing data to a specific way
        
        if loadedData == false {
            newList = getData()
            loadedData = true
            
            // don't filter for now
            
            // newList = coordinateCalculate.filterMercatorValues(inputList: newList)
            
            let auroraList = newList.map { $0.aurora }
            
            //print(auroraList.count)
            //print("check")
            
            maxAurora = auroraList.max()!
            
            
            // got rid of buplication widening for now. messes up values
            // newList = coordinateCalculate.widenCorrdinateList(inputList: newList)
        }

        let coordinateSquare = coordinateCalculate.tileToCoordinate(path.x, path.y, zoom: path.z)
        
        let auroraTile = coordinateCalculate.createTileAuroraList(inputTileCoordinateList: coordinateSquare,
                                                                  inputAuroraList: newList)
        let tileList = auroraTile.inputList
        let width = auroraTile.width
        let height = auroraTile.height
        let indexWidth = auroraTile.indexHeight // was auroraTile.indexWidth
        let indexHeight = auroraTile.indexWidth // was auroraTile.indexHeight
        
        let image = coordinateCalculate.createRectanglePNG(inputList: tileList,
                                               width: width,
                                               height: height,
                                               indexWidth: indexWidth,
                                               indexHeight: indexHeight,
                                               maxAurora: maxAurora)
        
        let finalImage = UIImage(cgImage: image)
        
        let urlAppendString = String(path.z) + "_" + String(path.x) + "_" + String(path.y)
        
        let fileUrl = tilePath?.appendingPathComponent("\(urlAppendString)" + ".png")
        
        if let newImage = finalImage.pngData() {
            try? newImage.write(to: fileUrl!)
        }
        

        
        
        /*
         
         For each tile create a file in one directory that will look like "directoryName/zpath_xpath_ypath.png"
         then each time / condition / delete all files and create new. that doesnt sound efficient,
         but i will track memory usage and see if its good enough
         
         */
        
        // Get to the directory, and check if path exists with path info
        /*
        func tileExists(for tileLocalPath: MKTileOverlayPath) -> Bool {
            
            let existingPath = tilePath?.appendingPathComponent("\(tileLocalPath.z)/\(tileLocalPath.x)/\(tileLocalPath.y).png")
            
            let filePath = existingPath!.path()
            let fileManager = FileManager.default
            return fileManager.fileExists(atPath: filePath)
            
        }
         */
        
        // print(path) basically url for the whole layout, all of the functionality will be done here.
        // slowly start getting back on track
      
        
        // data now is saved aurora data that we can use for our purpose, i'll starg with simple filtering
        
        
        // each method here does its functionality several times, create a one time function that will parse data once
        
        // pass all calculations here for tile processing.
       
        /*
        if tileExists(for: path) {
            
            
            // wont need soon
            
            let existingPath = tilePath?.appendingPathComponent("\(path.z)/\(path.x)/\(path.y).png") // was png
            tilePath = existingPath!
            
        } else {
            let sampleImage = UIImage(cgImage: createSimpleImage())
            
            let fileUrl = tilePath?.appendingPathComponent("sampleImage_1" + ".png")
            
            // Create image.
            
            if let newImage = sampleImage.pngData() {
                try? newImage.write(to: fileUrl!)
            }
            
            tilePath = fileUrl
        }
        */
        //coordinateCalculate.createTileAuroraList(inputTileCoordinateList: coordinate,
        //                                         inputAuroraList: <#T##[IndividualAuroraSpot]#>)
        
        return fileUrl!
    }
    
    
    func createSimpleImage() -> CGImage {
        
        let color = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.0)
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        var newColor: UInt32 = 0
        
        var gridList: [UInt32] = []
        
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            newColor += UInt32((1) * 255.0) << 24 + // alpha
            UInt32((blue) * 255.0) << 16 + // blue ?
            UInt32(0.5 * 255.0) << 8 + // green???
            UInt32(alpha * 255.0) // what
        }
        
        let totalNum = 256 * 256
        
        for _ in 0...totalNum {
            gridList.append(newColor)
        }
        
        let cgImg = gridList.withUnsafeMutableBytes { (ptr) in
            let ctx = CGContext(data: ptr.baseAddress,
                                width: 256,
                                height: 256,
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * 256,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue + CGImageAlphaInfo.premultipliedLast.rawValue)!  // CGImageAlphaInfo.premultipliedFirst.rawValue) // & CGBitmapInfo.alphaInfoMask.rawValue
            
            return ctx.makeImage()!
            
        }
        
        return cgImg
    }
    
    
    func getData() -> [IndividualAuroraSpot] {
        
        var list: [IndividualAuroraSpot] = []
        
        let fileDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let auroraPath = fileDirectory.appendingPathComponent("aurora.json")!
        
        do {
            let file = try FileHandle(forReadingFrom: auroraPath)
            let aurora = try JSONDecoder().decode(Aurora.self, from: file.availableData)
            
            for item in aurora.coordinates {
                let auroraItem = IndividualAuroraSpot(longitude: item.longitude, latitude: item.latitude, aurora: item.aurora)
                list.append(auroraItem)
            }
        } catch {
            print(error.localizedDescription)
        }
        return list
    }
}
