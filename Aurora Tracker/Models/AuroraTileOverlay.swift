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
    
    private var topLeftList: [IndividualAuroraSpot] = []
    private var bottomLeftList: [IndividualAuroraSpot] = []
    private var topRightList: [IndividualAuroraSpot] = []
    private var bottomRightList: [IndividualAuroraSpot] = []
    
    // create a load function and see if it helps? get info from local fileData.
    
    private var loadedData = false
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        
        
        // loads a lot of tiles, for each would need to create a drawing function.
        // since function provides info for a tile, i can just get each tile's info and cycle ith through a function ang get info.
        
        // Current function returns an URL and not a picture, would make sense for temp create url with picture,
        // and get appropriate naming for each tile.
        // but later would make sense to shorten functionality to return a picture. look more into this functionality of MKTileOverlay
        
        // For now this method looks for a custom created folder that contains all maps for several layers.
        // Dad suggested to render and create pictures individually, it's a great idea. I will work on it.
        
        // Look into loadTile and possibly override it to be able to perform async creation of new tiles for specific coordinates range
        /*
         
         Individual render plan:
         1. Calculate all visible tiles
         2. Calculate values within tiles.
         3. Drawing a gradient for each coordinate rectangle. // will be worked on later
         4. Creating a picture, and passing it to the function.
         
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
            createTileDirectory()
            newList = getData()
            loadedData = true
            
            // i may need to shift all coordinates to 180 longitude
            
            let auroraList = newList.map { $0.aurora }
            
            maxAurora = auroraList.max()!
            
            
            let listProduct = createSeparateLists(inputList: newList)
            
            bottomLeftList = listProduct[0]
            topLeftList = listProduct[1]
            bottomRightList = listProduct[2]
            topRightList = listProduct[3]
            
            /*
            if bottomLeftList.isEmpty || topLeftList.isEmpty || bottomRightList.isEmpty || topRightList.isEmpty {
                print()
            }
             */
        }

        let coordinateSquare = coordinateCalculate.tileToCoordinate(path.x, path.y, zoom: path.z)
        
        // write a function that will pass one of four lists
        
        var cycleList: [IndividualAuroraSpot] = []
        
        if coordinateSquare[0] <= 0 && coordinateSquare[1] < 180 {
            cycleList = bottomLeftList
        } else if coordinateSquare[0] >= 0 && coordinateSquare[1] < 180 {
            cycleList = topLeftList
        } else if coordinateSquare[0] <= 0 && coordinateSquare[1] >= 180 {
            cycleList = bottomRightList
        } else if coordinateSquare[0] >= 0 && coordinateSquare[1] >= 180 {
            cycleList = topRightList
        }

        
        /*
        if cycleList.isEmpty {
            print()
        }
         */
        // pass Z to transform list to mercator proportions?
        // pass rations and calculate with rations later on
        
        let auroraTile = coordinateCalculate.createTileAuroraList(inputTileCoordinateList: coordinateSquare,
                                                                  inputAuroraList: cycleList,
                                                                  zoom: path.z)
        let tileList = auroraTile.inputList
        let width = auroraTile.width
        let height = auroraTile.height
        let indexWidth = auroraTile.indexWidth
        let indexHeight = auroraTile.indexHeight
        
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
        

        return fileUrl!
    }
    
    
    func createSimpleImage() -> CGImage {
        
        // was used for testing purposes
        
        let color = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.0)
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        var newColor: UInt32 = 0
        
        var gridList: [UInt32] = []
        
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            newColor += UInt32((1) * 255.0) << 24 +
            UInt32((blue) * 255.0) << 16 +
            UInt32(0.5 * 255.0) << 8 +
            UInt32(alpha * 255.0)
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
                                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue + CGImageAlphaInfo.premultipliedLast.rawValue)!
            
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
        
        // shift 180 here?
        
        var outputList: [IndividualAuroraSpot] = []
        
        var firstList: [IndividualAuroraSpot] = []
        var secondList: [IndividualAuroraSpot] = []
        
        let halfListSize = list.count / 2
        
        var countIndex = 0
        var longitudeValue = 0.0
        
        for item in 0...(list.count-1) {
            if countIndex < halfListSize {
                longitudeValue = list[item].longitude + 180
                
                let newValue = IndividualAuroraSpot(longitude: longitudeValue,
                                                    latitude: list[item].latitude,
                                                    aurora: list[item].aurora)
                secondList.append(newValue)
                
            } else {
                longitudeValue = list[item].longitude - 180
                let newValue = IndividualAuroraSpot(longitude: longitudeValue,
                                                    latitude: list[item].latitude,
                                                    aurora: list[item].aurora)
                
                firstList.append(newValue)
                
            }
                
            countIndex += 1
        }

        outputList.append(contentsOf: firstList)
        outputList.append(contentsOf: secondList)
        
        /*
        for aurora in list {
            var newLongitude = 0.0
            
            if aurora.longitude > 179 { // =
                newLongitude = aurora.longitude - 180
            } else {
                newLongitude = aurora.longitude + 180
            }

            let newAurora = IndividualAuroraSpot(longitude: newLongitude,
                                                 latitude: aurora.latitude,
                                                 aurora: aurora.aurora)
            
            outputList.append(newAurora)
        }

         */
        return outputList
    }
    
    func createTileDirectory() {
        
        let documentDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let dirPathTiles = documentDirectory.appendingPathComponent("Tiles")
        
        if !FileManager.default.fileExists(atPath: dirPathTiles!.path()) {
            
            // if directory doesnt exist, create new.
            
            do {
                try FileManager.default.createDirectory(atPath: dirPathTiles!.path() , withIntermediateDirectories: true, attributes: nil)
                print("directory created")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func createSeparateLists(inputList: [IndividualAuroraSpot]) -> [[IndividualAuroraSpot]] {
        var outputList: [[IndividualAuroraSpot]] = []
        
        var topLeft: [IndividualAuroraSpot] = []
        var bottomLeft: [IndividualAuroraSpot] = []
        var topRight: [IndividualAuroraSpot] = []
        var bottomRight: [IndividualAuroraSpot] = []
        
        // consider creating 16 lists instead, or finding a quicker way to get info and parse it this way.
        
        // create a method that will be able to break down one giant list onto 4 lists.
        // boundaries are: [-90...0, 0...180], [0...90, 0...180], [-90...0, 180...360], [0...90, 180...360]

        
        // temp solution of providing 4 lists with borders
        
        
        for aurora in inputList {
            if aurora.latitude <= 0 && aurora.longitude <= 180 {
                bottomLeft.append(aurora)
            }
        }
        
        for aurora in inputList {
            if aurora.latitude >= 0 && aurora.longitude <= 180 {
                topLeft.append(aurora)
            }
        }
        
        for aurora in inputList {
            if aurora.latitude <= 0 && aurora.longitude >= 180 {
                bottomRight.append(aurora)
            }
        }
            
        for aurora in inputList {
            if aurora.latitude >= 0 && aurora.longitude >= 180 {
                topRight.append(aurora)
            }
        }

        outputList.append(bottomLeft)
        outputList.append(topLeft)
        outputList.append(bottomRight)
        outputList.append(topRight)
        
        
        return outputList
    }
}
