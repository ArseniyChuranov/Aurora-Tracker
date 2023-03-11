//
//  CoordinateCalculations.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 2/28/23.
//

import Foundation
import UIKit

class CoordinateCalculations {
    
    
    // Certain functions will be here for simplicity.
    // All of the methods will be used for tile view updates
    
    // This method converts globe coordinates to mercator ratios, needs resolution to create a more specific point. 
    
    func latLonToMercatonSecond(inputLatitude: Double, inputLongitude: Double, resolution: Int) -> (outputLatitude: Double, outputLongitude: Double) {

        
        let mapSide = Double(resolution) // custom square resolution
        
        let outputLongitude = inputLongitude * (mapSide / 360)
        
        
        let latRad = inputLatitude * Double.pi / 180
        
        let mercN = log(tan((Double.pi / 4) + (latRad / 2)))
        let outputLatitude = (mapSide / 2) - (mapSide * mercN / (2 * Double.pi))

        
        let roundedLongitude = Double(round(outputLongitude))
        let roundedLatitude = Double(round(outputLatitude))
        
        return (roundedLatitude, roundedLongitude)
    }
    
    // Filters all values that won't be represented on map projection
    
    func filterMercatorValues(inputList: [IndividualAuroraSpot]) -> [IndividualAuroraSpot] {
        var filteredAuroraList: [IndividualAuroraSpot] = []
        
        for aurora in inputList {
            if aurora.latitude < 86 && aurora.latitude > -86 { // look up upper bounds for mercator projection
                filteredAuroraList.append(aurora)
            }
        }
        
        return filteredAuroraList
    }
    
    func tileToCoordinate(_ tileX: Int, _ tileY: Int, zoom: Int) -> ([Double]) {
        // var outputLatitude: Double
        // var outputLongitude: Double
        var outputList: [Double] = [] // bottomLeftLat, bottomLeftLon, bottomRightLon, topLeftLat
        
        let res: Double = pow(2, Double(zoom))
        /*
        outputLongitude = (Double(tileX) / res) * 360.0 - 180.0
        
        outputLatitude = atan( sinh (.pi - (Double(tileY) / res) * 2 * Double.pi)) * (180.0 / .pi)
        */
        let bottomLeftLat = atan( sinh (.pi - (Double(tileY) / res) * 2 * Double.pi)) * (180.0 / .pi) //+ 85.0511287798066 // :((
        let bottomLeftLon = (Double(tileX) / res) * 360.0 // - 180.0
        let bottomRightLon = (Double(tileX + 1) / res) * 360.0 // - 180.0
        let topLeftLat = atan( sinh (.pi - (Double(tileY + 1) / res) * 2 * Double.pi)) * (180.0 / .pi) //+ 85.0511287798066
        
        outputList.append(bottomLeftLat)
        outputList.append(bottomLeftLon)
        outputList.append(bottomRightLon)
        outputList.append(topLeftLat)
        
        // let tileList = [tileY, tileX, zoom]
        
        // print("Original list \(tileList)")
        // print("Output list \(outputList)")
        
        return outputList
        
    }
    
    // function to create extra spaces for outOfBound values that would be repearted, will help to create a simpler function.
    // so far obsolete, not implemented
    
    func widenCorrdinateList(inputList: [IndividualAuroraSpot]) -> [IndividualAuroraSpot] {
        var outputList: [IndividualAuroraSpot] = []
        
        // cycle through all values, for each 360 values append one on the beginning, one in the end, append whole thing in the list
        
        let columnHeight = inputList.count / 360 // totalCount / amount of longitude values per line
        
        // function to append first and last item in a list
        
        func createNewColumn(inputRawList: [IndividualAuroraSpot]) -> [IndividualAuroraSpot] {
            // list will have columnHeight items, process it and return
            var newList: [IndividualAuroraSpot] = []
            
            let firstValue = inputRawList[0]
            let lastValue = inputRawList[inputRawList.count - 1]
            
            newList.append(firstValue)
            newList.append(contentsOf: inputRawList)
            newList.append(lastValue)
            
            return newList
        }
        
        // call createNewColumn func once for first lane of values
        let firstColumnSlice = inputList[0...columnHeight - 1]
        var firstColumn: [IndividualAuroraSpot] = []
        firstColumn.append(contentsOf: firstColumnSlice)
        
        outputList.append(contentsOf: createNewColumn(inputRawList: firstColumn))
       
        var startIndex = 0
        
        for _ in 0...359 {
            // write values into a list, copy first and last, append them.
            let rawListSlice = inputList[startIndex...(startIndex + columnHeight - 1)]
            var rawList: [IndividualAuroraSpot] = []
            rawList.append(contentsOf: rawListSlice)
            
            let finishedList = createNewColumn(inputRawList: rawList)
            
            outputList.append(contentsOf: finishedList)
            startIndex = startIndex + columnHeight
            rawList = []
        }
    
        
        let lastItemIndex = inputList.count - 1
        let lastList = inputList[(lastItemIndex + 1 - columnHeight)...lastItemIndex]
        var lastColumn: [IndividualAuroraSpot] = []
        lastColumn.append(contentsOf: lastList)
        
        outputList.append(contentsOf: createNewColumn(inputRawList: lastColumn))
        
        return outputList
    }
    
    // function that based on tile coordinates wll output all aurora values that would cover all tile with data
    
    func createTileAuroraList(inputTileCoordinateList: [Double],
                              inputAuroraList: [IndividualAuroraSpot]) -> (inputList: [IndividualAuroraSpot],
                                                                           width: Int,
                                                                           height: Int,
                                                                           indexWidth: [Double],
                                                                           indexHeight: [Double]) {
        // break down function
        
        var outputList: [IndividualAuroraSpot] = []
        var latitudeList: [IndividualAuroraSpot] = []
        
        
        
        let topLatitude = inputTileCoordinateList[0]
        let bottomLatitude = inputTileCoordinateList[3]
        let maxLongitude = inputTileCoordinateList[2]
        let minLongitude = inputTileCoordinateList[1]
        
        let celingLatitudeValue = topLatitude.rounded(.up)
        let floorLatitudeValue = bottomLatitude.rounded(.down)
        let startLongitudeValue = minLongitude.rounded(.down)
        let finishLongitudeValue = maxLongitude.rounded(.up)
        
        let topLatitudeDiff = abs(celingLatitudeValue - topLatitude) // difference between celing and input value
        let bottomLatitudeDiff = abs(bottomLatitude - floorLatitudeValue) // difference between bottom and floor
        let rightLongitudeDiff = abs(startLongitudeValue - minLongitude) // difference between start and right longitude
        let leftLongitudeDiff = abs(maxLongitude - finishLongitudeValue) // difference between end and left latitude
        
        var height = 0
        var width = 0
        var indexWidth: [Double] = []
        var indexHeight: [Double] = []
        
        let differenceTopLat = topLatitude - topLatitude.rounded(.down)
        let differenceBottomLat = bottomLatitude - bottomLatitude.rounded(.down)
        let differenceLeftLon = minLongitude - minLongitude.rounded(.down)
        let differenceRightLon = maxLongitude - maxLongitude.rounded(.down)
        
        let latitudeSquaresCount = (topLatitude.rounded(.up) - bottomLatitude.rounded(.down))
        let longitudeSquaresCount = (maxLongitude.rounded(.up) - minLongitude.rounded(.down))
        
        
        
        // insert giant if here
        
        if abs(topLatitude - bottomLatitude) > 1 || abs(maxLongitude - minLongitude) > 1 {
            // there are several vlues to be filles
            
            let differenceTopLat = topLatitude - topLatitude.rounded(.down)
            let differenceBottomLat = bottomLatitude - bottomLatitude.rounded(.down)
            let differenceLeftLon = minLongitude - minLongitude.rounded(.down)
            let differenceRightLon = maxLongitude - maxLongitude.rounded(.down)
            
            let latitudeSquaresCount = (topLatitude.rounded(.up) - bottomLatitude.rounded(.down))
            let longitudeSquaresCount = (maxLongitude.rounded(.up) - minLongitude.rounded(.down))
            
            for aurora in inputAuroraList {
                
                if aurora.longitude >= startLongitudeValue && aurora.longitude <= finishLongitudeValue {
                    if aurora.latitude >= floorLatitudeValue && aurora.latitude <= celingLatitudeValue {
                        latitudeList.append(aurora)
                    }
                }
            }
            
//            print(latitudeList)
//            print("original list parsed into a smaller list with only coordinates and values in a tile")
            
            let heightCount = latitudeList[0].latitude
            let widthCount = latitudeList[0].longitude
            
            // calculate width and height
            
            // another way to calculate height is to get first and last values, and subtract them.
            
            let firstHeight = latitudeList[0].latitude
            let lastHeight = latitudeList[latitudeList.count - 1].latitude
            
            let firstWidth = latitudeList[0].longitude
            let lastWidth = latitudeList[latitudeList.count - 1].longitude
            
            let altHeight = lastHeight + 1 - firstHeight
            let altWidth = lastWidth + 1 - firstWidth
            
            for item in latitudeList {
                if item.latitude == heightCount {
                    height = height + 1
                }
                if item.longitude == widthCount {
                    width = width + 1
                }
            }
            
            var rightIndex = width - 1
            var leftIndex = 0
            
            for _ in 0...(height - 1) {
                
//                if latitudeList.contains(where: { $0.longitude == 0 }) {
//                    print(latitudeList)
//                    print(rightIndex)
//                    print(leftIndex)
//                    print("first height \(firstHeight) and last height \(lastHeight)")
//                    print("firstWidth \(firstWidth) and last width \(lastWidth)")
                    
                    
                    // first latitude is repeated twice, maybe it has to do with indexation?
                    
                    // its because ive created outer edges...
                    // delet them
                    
                    
//                    print("height is \(height)")
//                    print("width is \(width)")
//                    print("alt width is \(altWidth)")
//                    print("alt height is \(altHeight)")
//                    print("altTotalCount is \(altWidth * altHeight)")
//                    print("total amount of items based on height and width is \(height * width)")
//                    print("total actual amount is \(latitudeList.count)")
//                    print("cycle check")
//                }
                
                let leftCoordinateAurora = latitudeList[leftIndex]
                let leftAuroraValue = leftCoordinateAurora.aurora
                
                let newLeftAurora = IndividualAuroraSpot(longitude: leftCoordinateAurora.longitude,
                                                         latitude: bottomLatitude,
                                                         aurora: leftAuroraValue)
                
                let righthCoordinateAurora = latitudeList[rightIndex]
                let rightAuroraValue = righthCoordinateAurora.aurora

                let newRightAurora = IndividualAuroraSpot(longitude: righthCoordinateAurora.longitude,
                                                          latitude: topLatitude,
                                                          aurora: rightAuroraValue)
                
                latitudeList[leftIndex] = newLeftAurora
                latitudeList[rightIndex] = newRightAurora
                
                
                
                rightIndex = rightIndex + width
                leftIndex = leftIndex + width
            }
            
            // repeat for width
            
            var topIndex = width * (height - 1)
            var bottomIndex = 0
            
            
            for _ in 0...(width - 1) {
                let bottomCoordinateAurora = latitudeList[bottomIndex]
                var bottomAuroraValue = bottomCoordinateAurora.aurora
                
                
                
                let bottomAuroraDifference = abs(bottomAuroraValue - latitudeList[bottomIndex + width].aurora)
                let changedBottomValue = bottomAuroraDifference * differenceLeftLon
                
                //print(changedBottomValue)
                
                bottomAuroraValue = changedBottomValue + bottomAuroraValue
                
                
                let newBottomAurora = IndividualAuroraSpot(longitude: minLongitude,
                                                           latitude: bottomCoordinateAurora.latitude,
                                                           aurora: bottomAuroraValue)
                
                let topCoordinateAurora = latitudeList[topIndex]
                
                var topAuroraValue = topCoordinateAurora.aurora
                
                
                
                let topAuroraDifference = abs(topAuroraValue - latitudeList[topIndex - width].aurora)
                let changedTopValue = topAuroraDifference * differenceRightLon
                
                topAuroraValue = topAuroraValue + changedTopValue
                
                let newTopAurora = IndividualAuroraSpot(longitude: maxLongitude,
                                                        latitude: bottomCoordinateAurora.latitude,
                                                        aurora: topCoordinateAurora.aurora)
                
                latitudeList[bottomIndex] = newBottomAurora
                latitudeList[topIndex] = newTopAurora
                
                bottomIndex = bottomIndex + 1
                topIndex = topIndex + 1
            }
            
            //print(latitudeList)
            //print("latitude list was altered")
            
            // returns latitude list
            
        } else {
            // each value is < 1, gradient needed to be filled based on rounded values.

            for aurora in inputAuroraList {
                
                if aurora.longitude >= startLongitudeValue && aurora.longitude <= finishLongitudeValue {
                    if aurora.latitude >= floorLatitudeValue && aurora.latitude <= celingLatitudeValue {
                        // create a column full of latitude values
                        latitudeList.append(aurora)
                    }
                }
            }
            
        }

        
        if latitudeList.count == 4 { // within 1 coordinate

            // leave this function for later
            
            var bottomLeftAuroraValue: Double = 0
            var topLeftAuroraValue: Double = 0
            var bottomRightAuroraValue: Double = 0
            var topRightAuroraValue: Double = 0
            

            
            // Bottom Left Corner
            
            let diffLat = abs(latitudeList[0].aurora - latitudeList[1].aurora)
            let diffLon = abs(latitudeList[0].aurora - latitudeList[2].aurora)
            
            
            let valueLat = diffLat * differenceBottomLat
            let valueLon = diffLon * differenceLeftLon
            
            
            bottomLeftAuroraValue = latitudeList[0].aurora * 2
            bottomLeftAuroraValue = bottomLeftAuroraValue + valueLon + valueLat
            bottomLeftAuroraValue = bottomLeftAuroraValue / 2
            
            // top Left Corner
            
            let topValueLeftLat = diffLat * differenceTopLat
            let topValueLeftLon = diffLon * differenceLeftLon // same as valueLon
            
            topLeftAuroraValue = latitudeList[0].aurora * 2
            topLeftAuroraValue = topLeftAuroraValue + topValueLeftLat + topValueLeftLon
            topLeftAuroraValue = topLeftAuroraValue / 2
            
            // bottom right corner
            
            let bottomValueRightLat = diffLat * differenceBottomLat
            let bottomValueRightLon = diffLon * differenceRightLon
            
            bottomRightAuroraValue = latitudeList[2].aurora * 2
            bottomRightAuroraValue = bottomRightAuroraValue + bottomValueRightLat + bottomValueRightLon
            bottomRightAuroraValue = bottomRightAuroraValue / 2
            
            // top right corner
            
            let topRightValueLat = diffLat * differenceTopLat
            let topRightValueLon = diffLon * differenceRightLon
            
            topRightAuroraValue = latitudeList[2].aurora * 2
            topRightAuroraValue = topRightAuroraValue + topRightValueLat + topRightValueLon
            topRightAuroraValue = topRightAuroraValue / 2

            let coordinateList = [bottomLatitude, minLongitude, maxLongitude, topLatitude]
            let auroraFinalValues = [bottomLeftAuroraValue, bottomRightAuroraValue, topLeftAuroraValue, topRightAuroraValue]
            
            
            // return list normally
            
            let finalAuroraValues = AuroraCoordinateRectangle(id: UUID(), coordinateList: coordinateList, auroraList: auroraFinalValues)
            
            let product = createGradientRectangle(inputRectangle: finalAuroraValues, resolution: 256)

        }
            
            // i can check for both rounded conditions and then process with several different loops.
            // if all values are rounded then process is same as it is, if they are not, we are going to create extra squares
            
        if topLatitudeDiff == 0 && bottomLatitudeDiff == 0 {
            // top latitude and bottom latitude are both whole numbers
            if rightLongitudeDiff == 0 && leftLongitudeDiff == 0 {
                // longitude and latitude are both whole numbers
                outputList.append(contentsOf: wholeNumberProcessing(inputAuroraList: inputAuroraList,
                                                                    minLongitude: minLongitude,
                                                                    maxLongitude: maxLongitude,
                                                                    bottomLatitude: bottomLatitude,
                                                                    topLatitude: topLatitude))
                
                // list contains only of whole numbers, end of function

            }
            
        }
            
            // create a function that will create a gradient values.
        
        
        for aurora in inputAuroraList {
            if aurora.longitude >= minLongitude && aurora.longitude <= maxLongitude { // longitude check
                // if latitude is >0, still maybe 2 whole longirude points, account for that
                if aurora.latitude >= bottomLatitude && aurora.latitude <= topLatitude { // latitude check
                    outputList.append(aurora)
                }
            }
        }
    
        
        // here prep
        
        // figure on what conditions i will be passing each of this functions.
        // in certain dimensions there are no reasons to call this method
        indexWidth = spreadCoordinatesForRes(minValue: minLongitude, maxValue: maxLongitude, dimension: width)
        indexHeight = spreadCoordinatesForRes(minValue: bottomLatitude, maxValue: topLatitude, dimension: height)
        
        
        
//        print("IndexWidth = \(indexWidth)")
//        print("indexHeight = \(indexHeight)")
//        print(indexWidth.count)
//        print(indexHeight.count)
//        print(width)
//        print(height)

//        print("check")
   
        // replace outpul list with latitude list
        
        return (latitudeList, width, height, indexWidth, indexHeight)
        
        // createRactanglePNG here
        
    }
    
    
    // png creation plus return, last func here
    
    func createRectanglePNG(inputList: [IndividualAuroraSpot],
                            width: Int,
                            height: Int,
                            indexWidth: [Double],
                            indexHeight: [Double],
                            maxAurora: Double) -> CGImage {
        // breaking down from other function to simplify it
        
        
        
        var testList: [IndividualAuroraSpot] = []
        
        var longitudeIndex = 0
        var latitudeIndex = 0
        
        // create indexW and indexH
        // see if i need to flip lists. see original orientation of a list
        // list for function starts from bottom, where largest latitude value is 256, not 0. flip the list
        
        // this functiob has to be rethinked to work properly
        
        /*
         
         heightIndex =
         widthindex = how many pixels per each line would be taken
         
         */
    
        
        // its wrong look into it more
        
        
        var firstItemInList = true
        var firstLine = true
        
        // for each coordinate in coordinates, just replace longitude and latitude with correct values
        
        var newIndexHeight: [Double] = []
        //newIndexHeight.append(256.0)
        // var varIndexHeight = indexHeight
        //varIndexHeight.remove(at: 0)
        newIndexHeight = indexHeight.reversed()
        //print(newIndexHeight)
        var auroraIndex = 0
        
//        print("inputlist")
//        print(inputList)
//        print("next")
        
        // see if would need to create a new value or just append it correctly
        
        // swap height list so it starts with the highest value, keep the rest as it suppose to be
        // highest value will be 256. i think.

        // cycle through list and create a flipped list that starts with 256, and decends to last value.
        // or append 256, flip list, and then took out 0?
        
        
        for longitude in indexWidth {
            var originalFlip: [IndividualAuroraSpot] = []
            
            // maybe manually append 255 to each to draw borders?
 
            for latitude in newIndexHeight {

                
                let newCorrdinate = IndividualAuroraSpot(longitude: Double(longitude),
                                                         latitude: Double(latitude),
                                                         aurora: inputList[auroraIndex].aurora)
                auroraIndex = auroraIndex + 1

                // testList.append(newCorrdinate)
                originalFlip.append(newCorrdinate)
                
            }
            
            // im returning to this method.
//            originalFlip = originalFlip.reversed() // might work or i might need to reshape whole function
            testList.append(contentsOf: originalFlip)
            
//            print("one column is filled, last value is \(originalFlip[0])")
            
            originalFlip = []

//            print(longitudeIndex)
//            print("filled one column")
        }
                
//        print(width)
//        print(height)
//        print(indexWidth)
//        print(indexHeight)
//        print(testList)
//        print("simple coordinate list ")
        
        /*
        let checkForZero = testList.map { $0.aurora }
        
        if checkForZero.max() != 0 {
            let product = parseMercatorToRectangles(mercatorGrid: testList, resolution: 256, height: height, width: width)
        }
         
         */
        // passing only if there are no zeros
        
        // this function from original accounts for edges, check is thats what i want.
        // since resolution is passed, which coule lead to possible problems
        
        let auroraQuickList = testList.map { $0.aurora }
        
        var product: [AuroraCoordinateRectangle] = []
//
        for aurora in auroraQuickList {
            if aurora != 0 {
                // switching height and width? im stoopid ok.
                
//                print("width")
//                print(indexWidth)
//                print("heigth")
//                print(newIndexHeight)
                //print(testList.count)
//                print(product.count)
            
                
                product = parseMercatorToRectangles(mercatorGrid: testList, resolution: 256, height: width, width: height)
//                print("cycle is fuul of non0")
                //print(product)
                break
            }
        }
        
        // og method
        // let product = parseMercatorToRectangles(mercatorGrid: testList, resolution: 256, height: height, width: width)
        
        // pay close attention to range of each value
        // latitude looks good, longitude is wrong
        // longitude might be out of range, ots 0...256, instead of 0...255
        
        // print(product)
        
        // one of the highest values is 0 instead of 255, check and fix it. this is possibly what was throwing off my triangles.
        // list shifts slowly
        
        
        //
        
        
//        print("list was pasred to individual rectangles")

        var gradientTestValuesList: [Double] = []
        var gradientTestIndexList: [Int] = []
        
        for item in product {
            let gradientProduct = createGradientRectangle(inputRectangle: item, resolution: 256)
            
            gradientTestValuesList.append(contentsOf: gradientProduct.valueList)
            gradientTestIndexList.append(contentsOf: gradientProduct.indexList)

        }
        
        // Create an empty list that will represent pixel values in Double.
        
        var gradientPixelArray: [Double] = []

        // Create a list with each pixel for a tile written as 0.
        
        for _ in 0...((256 * 256) - 1) {
            gradientPixelArray.append(0.0)
        }
        
        var highestIndex = 0
        
        var newIndexList: [Int] = []
        
        for item in gradientTestIndexList {
            newIndexList.append(item - 1)
        }
        
//        for item in gradientTestIndexList {
//            if item > highestIndex {
//                highestIndex = item
//            }
//        }
        /*
        var lackingIndex = 1
        
        for _ in gradientTestIndexList {
            if gradientTestIndexList.contains(lackingIndex) {
                lackingIndex = lackingIndex + 1
            } else {
                print("lacking index is \(lackingIndex)")
                print("stop")
            }
        }
        */
//        print("highest index value in gradiesnt lis it \(highestIndex)")

//        print("sqRoot of totalamount of indexes values \(sqrt(Double(gradientTestIndexList.count)))")
//        print("total values: \(gradientTestValuesList.count)")
        //print(gradientTestValuesList)
        // print(gradientPixelArray.count)
//        if !gradientTestIndexList.isEmpty {
//            print(gradientTestIndexList[1000...1700])
//            print(createGradientRectangle(inputRectangle: product[5], resolution: 256))
//        }
//        print("total indexes: \(newIndexList.count)")
//        print("seewassup")
        
        
        
        

        var cycleIndex = 0
        
        for indexValue in gradientTestIndexList { // was newIndexList
            gradientPixelArray[indexValue] = gradientTestValuesList[cycleIndex]
            cycleIndex = cycleIndex + 1
        }
        
        // Create an empty UInt32 list, that will be used to fill with actual color value.
        
        var pixelGrid: [UInt32] = []
        
        var auroraAlpha: Double = 0
        
        if maxAurora != 0 {
            auroraAlpha = 1.0 / maxAurora // this is amount of increments from 0 to 1 based on aurora strength
//            print(auroraAlpha)
//            print(maxAurora)
        }
        
        
        // Create color scheme for overlay image
    
        let color = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.0)
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        
        // For each gradient value add either a value or an empty pixel
        
        for item in gradientPixelArray {
            if item != 0 {
                var newColor: UInt32 = 0
                let currentAuroraAlpha = Double(item) * auroraAlpha
                if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    newColor += UInt32((1) * 255.0) << 24 + // alpha
                    UInt32((blue) * 255.0) << 16 + // blue ?
                    UInt32((currentAuroraAlpha) * 255.0) << 8 + // green???
                    UInt32(alpha * 255.0) // what
                    
                    pixelGrid.append(newColor)
                    
                }
                
            } else {
                var newColor: UInt32 = 0
                if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    newColor += UInt32(1 * 255.0) << 24 + // alpha
                    UInt32(green * 255.0) << 16 +
                    UInt32(blue * 255.0) << 8 +
                    UInt32(alpha * 255.0)
                    
                    pixelGrid.append(newColor)
                }
            }
            
        }
        
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
        
        
        
        // create and save test triangle, start breaking down function
        
        // cycle throuth each parsed rectangle, and then create output

        
        // temp function to create images.
        
        func createSimpleImage(inputList: [UInt32]) -> CGImage {
            
            var gridList = inputList
            
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

        
        let finalImage = createSimpleImage(inputList: rotateImage(inputImage: pixelGrid))
        
        return finalImage
    }
    
    // function to process only whole nums
    
    func wholeNumberProcessing(inputAuroraList: [IndividualAuroraSpot],
                               minLongitude: Double,
                               maxLongitude: Double,
                               bottomLatitude: Double
                               , topLatitude: Double) -> [IndividualAuroraSpot] {
        var outputList: [IndividualAuroraSpot] = []
        for aurora in inputAuroraList {
            if aurora.longitude >= minLongitude && aurora.longitude <= maxLongitude { // longitude check
                // if latitude is >0, still maybe 2 whole longirude points, account for that
                if aurora.latitude >= bottomLatitude && aurora.latitude <= topLatitude { // latitude check
                    outputList.append(aurora)
                }
            }
        }
        
        return outputList
    }
    
    // function to create coordinates for new tile
    
    func spreadCoordinatesForRes(minValue: Double, maxValue: Double, dimension: Int) -> [Double] {
        
        // I restructute this function so it returns indexes per each item, 0...anyNumberBelow255
        /*
         
         This is a bit of a complex sotuation, that doesn't account for each part.
         we are recieving a number of coordinates we are going to implement.
         total number will be 2...SomeAmount
         
         case with domention 2 will have 2 coordinates, min value is equal to 0,
         max value is equal to border if is present (44.5 -> 45.0 -> 45.5),
         255 will be equal to last value in this case.
         
         this is why its more complex and i would need to account for every possibly scenario.
         
         This function will not recieve any scenarios with 2 dimensions and 2 output values
         a.k.a "Coordinates inside 0...1 coordinate", no values within borders of 1x1 square of coordinates.
         
         it might have a dimension of 2, but it will send 3 values, [0.0, <BorderValue>, 256.0]
         I might need to pass a different system, not dimensions since it might not be very clear and representitive.
         
         */
        
        var outputList: [Double] = []
        var indexList: [Double] = []
        
        // output rules
        
        // 1st number in index will always be 0.0, last will be 256.
        // 1st index == 0 + startValueProportion * increments
        
        
        let widthIncrements = 256 / abs(maxValue - minValue) // pixels per whole width of a tile
        
        // cycle through each longitude value to determine proportions given each per increment
        // compile a list of longitudes? create one here?
        // create a list of proportional values, from 0.001 to 1.0.
        
        let startValueProportion = abs(minValue - minValue.rounded(.up)) // is it rounded down or up? // probably up
        let lastValueProportion = abs(maxValue - maxValue.rounded(.down))
        let wholeNumersAmount = abs(maxValue.rounded(.down) - minValue.rounded(.up))
        
        // what if i can just subtract one from each? but proportions are in question
        
        // (256 - first index+next = lastIndex+previous) / whole num amount
        
        
        var firstPixelWidth = startValueProportion * widthIncrements
        var lastPixelWidth = lastValueProportion * widthIncrements
        var wholePixels = wholeNumersAmount * widthIncrements
        
//        print("first pixel \(firstPixelWidth)")
//        print("whole pixels \(wholePixels)")
//        print("last pizel \(lastPixelWidth)")
        
//        wholePixels.round()
        
        firstPixelWidth.round()
        lastPixelWidth.round()
        wholePixels.round()
        
        var itemsNum = 0
        
//        print("first pixel rounded \(firstPixelWidth)")
//        print("whole pixels rounded \(wholePixels)")
//        print("last pixel rounded \(lastPixelWidth)")
//
        // indexList.append(0.0)
        
        // change dimension to 4 cases as well.
        
        
        
        if dimension == 2 {
            // this one might be changed later
            //indexList.append(firstPixelWidth)
            
            
            
            outputList.append(firstPixelWidth)
            //outputList.append(lastPixelWidth)
            
        }
        /*
        else if dimension <= 4 && dimension > 2 {
            // figure this here.
            // i would still need to create bounds
            
            print(dimension)
            
            print("first pixel rounded \(firstPixelWidth)")
            print("whole pixels rounded \(wholePixels)")
            print("last pixel rounded \(lastPixelWidth)")
            
            // 0, 250, 6
            // 0.. 250 / 3 whole,
            //
            
            print("check")
        }
        */
        else {
            var itemsToFill = dimension - 2 // 0.0 <stuff to fill>
            var fillLast = false
            
            if firstPixelWidth != 0 {
                outputList.append(firstPixelWidth)
                itemsToFill = itemsToFill - 1
            }
            
            if lastPixelWidth != 0 {
                itemsToFill = itemsToFill - 1
                fillLast = true
            }
            
            var leftover: Double = 0
   
            // maybe have an if/else here?
            
            // if itemstoFill < 1, do a thing
            
            if itemsToFill <= 0 {
                // skip?
                
            } /*
            else if itemsToFill == 1 {
                print(dimension)
                
                print("first pixel rounded \(firstPixelWidth)")
                print("whole pixels rounded \(wholePixels)")
                print("last pixel rounded \(lastPixelWidth)")
                
                outputList.append(wholePixels)
                
                // this means that
                
                
                print("check")
                
            } */
            else {
                for _ in 0...(itemsToFill - 1) {
                    
                    var wholePixel = wholePixels / Double(itemsToFill + 1)
                    
                    leftover = leftover + (wholePixel - wholePixel.rounded(.down))
                    
                    if leftover >= 1 {
                        wholePixel.round(.up)
                        leftover = 0.0
                    } else {
                        wholePixel.round(.down)
                    }
                    
                    outputList.append(wholePixel)
                }
            }
            
            
            if leftover != 0.0 {
                let lastIncremened = outputList[outputList.count - 1]
                outputList[outputList.count - 1] = lastIncremened + 1
            }
            
            if fillLast {
                outputList.append(lastPixelWidth)
            }
            
            itemsNum = itemsToFill
        }
        
        
//        var sum = 0.0
//        for item in outputList {
//            sum = sum + item
//        }

        
//        print(sum)
//        print("cycle filled this many items \(itemsNum)")
//        print("output list")
//        print(outputList)
//        print(outputList.count) // output list will always be dimensions - 2
//        print("actual indexes")
    
        
        var actualIndexes: [Double] = []
        var indexAmount = 0.0
        
        actualIndexes.append(0.0)
        
        for index in outputList {
            //output list will always have correct num of incements
            indexAmount = indexAmount + index
            actualIndexes.append(indexAmount)
        }
        
        actualIndexes.append(255.0) // should it be 255? was 256, might actually be correct to have 256 instead.
        
        /*
        if lastPixelWidth != 0 {
            
            print("this is last index \(lastPixelWidth)")
            
            var lastValue = actualIndexes[actualIndexes.count - 1]
            lastValue = lastValue + indexList[indexList.count - 1]
            print(lastValue)
            print("check")

            // add last two?
        }
        */
        
        // removes last item? always?
        
//        print(actualIndexes)
//        print(actualIndexes.count)
//        print(dimension)
        return actualIndexes
    }
    
    // used to append elements for pixelCount items to return actual aurora positions.
    
    func createIndexes(inputList: [Double]) -> [Double] {
        var outputList: [Double] = []
        var indexAmount = 0.0
        
        outputList.append(0.0)
        
        for index in inputList {
            //output list will always have correct num of incements
            indexAmount = indexAmount + index
            outputList.append(indexAmount)
        }
        
        outputList.append(256.0) // ill keep it as an outOfBound index for now. as later i might be able to purely avoid it.
        
        return outputList
    }
    
    // Cycles through total number of avaliable aurora values, then creates struct that represents aurora values as corners and coordinates.
    // Used to create gradient tiles later.
    
    func parseMercatorToRectangles(mercatorGrid: [IndividualAuroraSpot],
                                   resolution: Int,
                                   height: Int,
                                   width: Int) -> ([AuroraCoordinateRectangle]) {
        var outputRectangleList: [AuroraCoordinateRectangle] = []
        
        
        // Rewrite this function to draw only in limitation within one tile (256x256)
        // It will be a much shorter functiuon and will need a lot of rework
        // some restructure will be needed.
        
        // input coordinates will be translated to a tile 256x256, take this in account.
        
        
        /*
         Plan:
            1. Сycle through a total amount of elements to create a struct with a rectangle corners.
            2. Based on certain conditions execute one of 4 scenarios
            3. Filter and append only structs that have any Aurora value that is not 0, if all 4 are zeros, it would be an empty rectangle without gradient.
         
         */
        
        let listLenght = mercatorGrid.count
   
        var beginningIndex = 0
        var tempIndexSkip = 0
        
        var latitudeIndex = 0
        var longitudeIndex = 0
        
        var heightIndexList = 0
        
        
        // for tile composition i wont need latitude/longitude indexes i believe. i would need to double check.
          
        for aurora in 0...(listLenght - 1 - height) { // later change to total list count.
            
            // Start each cycle with init of variables.
            
            var BottomLeftCornerLat: Double = 0
            var BottomleftCornerLon: Double = 0
            var BottomRightCorner: Double = 0
            var TopLeftCorner: Double = 0
            
            var AuroraBottomLeftCorner: Double = 0
            var AuroraBottomRightCorner: Double = 0
            var AuroraTopLeftCorner: Double = 0
            var AuroraTopRightCorner: Double = 0
           
            // when index is 360 for longitude, do last set of operations and this will be the end
            

            if latitudeIndex == (height - 1) {
                
                // End of Latitude index, start counting again.
                
                latitudeIndex = 0
                tempIndexSkip = tempIndexSkip + 1
                
                heightIndexList = heightIndexList + height
                
//                if !outputRectangleList.isEmpty {
//                    print(outputRectangleList)
//                    print(mercatorGrid)
//                    print(height)
//                    print(outputRectangleList.count)
//                    print("cycle shows so far this result.")
//
//                }
                
                
                // 0...170 = 171 items
                // 171...341 = 171 + 171 items
                // 342...512 = 171 + 171 + 171 items
                
            } else {
                
                // 0...170, count and add
                
                if longitudeIndex == width - 2 {
                    
                    // cut it short and append last column?
                    
                    // Last longitude line, index will be out of bound, so for each longitude a value from 0 to 359 will be provided
                    // All latitude values will be normal, only longitude values will be different
                    // Also check for last latitude value here
                    // For coordinates just use resolution value
                    
                    if latitudeIndex == height - 1 {
                        
                        // beginning index = 0..359
                        
                        // Last iteration of a func here
                        
                        //one to last column, last item, to reverse repetition
                        
                        AuroraBottomLeftCorner = mercatorGrid[aurora].aurora
                        AuroraTopLeftCorner = mercatorGrid[aurora + 1].aurora
                        AuroraBottomRightCorner = mercatorGrid[aurora + height - 1].aurora
                        AuroraTopRightCorner = mercatorGrid[aurora + height].aurora
                        
                        
                        BottomLeftCornerLat = mercatorGrid[aurora].latitude
                        BottomleftCornerLon = mercatorGrid[aurora + 1].longitude
                        BottomRightCorner = mercatorGrid[aurora].longitude
                        TopLeftCorner = mercatorGrid[aurora + 1].latitude
                        
                        latitudeIndex = latitudeIndex + 1
                        beginningIndex = beginningIndex + 1
                        
                        
                        
                    } else {
                        
                        // beginning index = 0..359
                        
                        AuroraBottomLeftCorner = mercatorGrid[aurora].aurora
                        AuroraTopLeftCorner = mercatorGrid[aurora + 1].aurora
                        AuroraBottomRightCorner = mercatorGrid[aurora + height - 1].aurora
                        AuroraTopRightCorner = mercatorGrid[aurora + height].aurora
                        
                        BottomLeftCornerLat = mercatorGrid[aurora].latitude
                        BottomleftCornerLon = mercatorGrid[aurora].longitude
                        BottomRightCorner =  mercatorGrid[aurora + height].longitude
                        TopLeftCorner = mercatorGrid[aurora + height + 1].latitude
                        
                        beginningIndex = beginningIndex + 1
                        latitudeIndex = latitudeIndex + 1
                        
                    }
                    
                    let resultRectangle = AuroraCoordinateRectangle(id: UUID(), coordinateList: [BottomLeftCornerLat, BottomleftCornerLon, BottomRightCorner, TopLeftCorner],
                                                                    auroraList: [AuroraBottomLeftCorner, AuroraBottomRightCorner, AuroraTopLeftCorner, AuroraTopRightCorner])
                    
                    // If any of Aurora values in list is not zero, add toa list.
                    
                    for auroraValue in resultRectangle.auroraList {
                        if auroraValue != 0 {
                            outputRectangleList.append(resultRectangle)
                            break
                        }
                    }
                    
                    
                    
                } else {
                    
                    // longitude index 0...358
                    
                    if latitudeIndex == height - 2 {
                        
                        
                        // its a different list, on last item
                        
                        
                        
                        // 0...170, 171...
                        // Last rectangle in the Latitude line
                        // I might instead follow a differnt path, since I won't be needing to cycle through each aurora, i would need less value
                        // longitudeIndex will be used to determine Longitude Count, 0...359
                        
                        AuroraBottomLeftCorner = mercatorGrid[aurora].aurora
                        AuroraTopLeftCorner = mercatorGrid[aurora + 1].aurora
                        AuroraBottomRightCorner = mercatorGrid[aurora + height].aurora
                        AuroraTopRightCorner = mercatorGrid[aurora + height + 1].aurora
                        
                        BottomLeftCornerLat = mercatorGrid[aurora].latitude
                        BottomleftCornerLon = mercatorGrid[aurora].longitude
                        BottomRightCorner = mercatorGrid[aurora + height].longitude
                        TopLeftCorner = mercatorGrid[aurora + 1].latitude
                        
                        latitudeIndex = latitudeIndex + 1
                        longitudeIndex = longitudeIndex + 1
                        
                        
                    } else {
                        
                        // latitude index 0...169
                        
                        AuroraBottomLeftCorner = mercatorGrid[aurora].aurora
                        AuroraTopLeftCorner = mercatorGrid[aurora + 1].aurora
                        AuroraBottomRightCorner = mercatorGrid[aurora + height].aurora
                        AuroraTopRightCorner = mercatorGrid[aurora + height + 1].aurora
                        
                        BottomLeftCornerLat = mercatorGrid[aurora].latitude
                        BottomleftCornerLon = mercatorGrid[aurora].longitude
                        BottomRightCorner = mercatorGrid[aurora + height].longitude // simply wrong?
                        TopLeftCorner = mercatorGrid[aurora + 1].latitude
                        
                        latitudeIndex = latitudeIndex + 1
                        
                        
                    }
                    
                    let resultRectangle = AuroraCoordinateRectangle(id: UUID(), coordinateList: [BottomLeftCornerLat, BottomleftCornerLon, BottomRightCorner, TopLeftCorner],
                                                                    auroraList: [AuroraBottomLeftCorner, AuroraBottomRightCorner, AuroraTopLeftCorner, AuroraTopRightCorner])
                    
                    for auroraValue in resultRectangle.auroraList {
                        if auroraValue != 0 {
                            outputRectangleList.append(resultRectangle)
                            break
                        }
                    }
                }
            }
        }
        return outputRectangleList
    }
    
    func createGradientRectangle(inputRectangle: AuroraCoordinateRectangle, resolution: Int) -> (valueList: [Double], indexList: [Int]) {
        var outputValuesList: [Double] = []
        var outuupIndexList: [Int] = []
        
        let bottomLeftCoordinateLat = inputRectangle.coordinateList[0]
        let bottomLeftCoordinateLon = inputRectangle.coordinateList[1]
        let bottomRightCoordinateLon = inputRectangle.coordinateList[2]
        let topLeftCoordinateLat = inputRectangle.coordinateList[3]
        
        let auroraBottomLeftCorner: Double = inputRectangle.auroraList[0] // 0
        let auroraBottomRightCorner: Double = inputRectangle.auroraList[1] // 0
        let auroraTopLeftCorner: Double = inputRectangle.auroraList[2] // 1
        let auroraTopRightCorner: Double = inputRectangle.auroraList[3] // 1
        
        
        /*
         BEFORE CHANGES
         
         var bottomLeftCoordinateLat = inputRectangle.coordinateList[0]
         var bottomLeftCoordinateLon = inputRectangle.coordinateList[1]
         var bottomRightCoordinateLon = inputRectangle.coordinateList[2]
         var topLeftCoordinateLat = inputRectangle.coordinateList[3]
         
         var auroraBottomLeftCorner: Double = inputRectangle.auroraList[0]
         var auroraBottomRightCorner: Double = inputRectangle.auroraList[1]
         var auroraTopLeftCorner: Double = inputRectangle.auroraList[2]
         var auroraTopRightCorner: Double = inputRectangle.auroraList[3]
         
         
         
         */
        
        
        /*
         
         how i would use width and height to generate squares and conditions for it
         /Users/arseniy/Downloads
         width and height would be calculated based on coordinate difference
         
         coordinate differnce - 1 will create a width and height where only coordinate values will be filled and rest is inbetween
         
         coorfinate differnece -2 will create a filler for only empty spots between
         
         as i write this function, it will only fill coordinate for low left corner, and inbetween other coordinates,
         everything else will be filled by next iteration
         
         
         
         
         */
        
        let height = abs(Int(topLeftCoordinateLat - bottomLeftCoordinateLat))
        let width = abs(Int(bottomLeftCoordinateLon - bottomRightCoordinateLon))
        
        var oneBigValuesList: [Double] = []
        
        // create a list of aurora values based on height
        
        // height list goes from bottom to top, where first value is bottomLeftCorner
        
        
        
        var auroraHeightFirstLineValue: [Double] = []
        var reversedArray: [Double] = []
        
        auroraHeightFirstLineValue.append(auroraBottomLeftCorner) // adding first aurora value
        
        var auroraHeightLastLineValue: [Double] = []
        var reversedArrayRight: [Double] = []
        
        auroraHeightLastLineValue.append(auroraBottomRightCorner)
        
        let auroraDifferenceLeft = abs(auroraBottomLeftCorner - auroraTopLeftCorner)
        var smallerLeft = 0.0
        
        if auroraBottomLeftCorner > auroraTopLeftCorner {
            smallerLeft = auroraTopLeftCorner
        } else {
            smallerLeft = auroraBottomLeftCorner
        }
        
        if height == 0 || width == 0 {
            print(inputRectangle)
            print("why")
        }
        
        //auroraHeightFirstLineValue.append(auroraBottomLeftCorner) // adding first aurora value
        
        // if defference is zero just add one?
        
        if height == 1 {
            // if there are no differences in height, next value is next avaliable value
            
            auroraHeightFirstLineValue.append(auroraTopLeftCorner)
            auroraHeightLastLineValue.append(auroraTopRightCorner)
            
            // then we check for any width, if there is any, then we can make wide line, if not = we create a single dot
            
            // its rectangle by side to side
            
            // if height is equal to 1, meaning that i would need to add only 1 lane, what to do?
            
            
        } else {
            // rest of code
            
            for item in 0...(height - 1) { // for each cell, add incremental step to a value // was 1
                
                var appendingValue: Double = 0
                
                if auroraDifferenceLeft == 0 { // if there are no difference, will it with Bottom value since they all same.
                    appendingValue = auroraBottomLeftCorner
                } else {
                    appendingValue = Double((Double(item) * auroraDifferenceLeft) / Double(height)) + smallerLeft
                }
                reversedArray.append(appendingValue)
                // item is a step from 0 to last, i will iuse it as increments
            }
            
            if auroraBottomLeftCorner > auroraTopLeftCorner {
                reversedArray.reverse()
            }
            
            auroraHeightFirstLineValue.append(contentsOf: reversedArray)
                    
            // repeat same with last values so we know how to increment per each list
                           
            let auroraDifferenceRight = abs(auroraBottomRightCorner - auroraTopRightCorner)
            var smallerRight = 0.0
            
            
            if auroraBottomRightCorner > auroraTopRightCorner {
                smallerRight = auroraTopRightCorner
            } else {
                smallerRight = auroraBottomRightCorner
            }
            
            for item in 0...(height - 1) { // for each cell, add incremental step to a value // was one
                var appendingValue: Double = 0
                
                if auroraDifferenceRight == 0 { // if there are no difference, will it with Bottom value since they all same.
                    appendingValue = auroraBottomRightCorner
                } else {
                    appendingValue = Double((Double(item) * auroraDifferenceRight) / Double(height)) + smallerRight
                }
                reversedArrayRight.append(appendingValue)
                // item is a step from 0 to last, i will iuse it as increments
            }
            
            if auroraBottomRightCorner > auroraTopRightCorner { // works
                reversedArrayRight.reverse()
            }
            
            auroraHeightLastLineValue.append(contentsOf: reversedArrayRight)
        }
        
        func createGradientList(leftValue: Double, rightValue: Double, width: Int) -> [Double] {
            var gradientList: [Double] = []
            var productArray: [Double] = []
            
            
            // start with appending left value
            gradientList.append(leftValue)
            
            // define which is larger
            
            let differenceValue = abs(leftValue - rightValue)
            var smallerValue = 0.0
            
            if leftValue > rightValue {
                smallerValue = rightValue
            } else {
                smallerValue = leftValue
            }
            
            if width - 1 == 0 {
                
                // if width is 0, then we need to return, since we already have a product which is first item in line
                
            } else {
                for item in 1...(width - 1) { // was 1
                    var appendingValue = 0.0
                    
                    if differenceValue == 0 {
                        appendingValue = leftValue
                    } else {
                        appendingValue = Double(Double(item) * differenceValue / Double(width)) + smallerValue
                    }
                    
                    
                    productArray.append(appendingValue)
                }
            }
            
            
            if leftValue > rightValue {
                productArray.reverse()
            }
            
            gradientList.append(contentsOf: productArray)
            return gradientList
        }
        
        
        
        
        
        // now when we have a list, we can create a new set of lists for each value in this list
        
        var layeredList: [[Double]] = []
        
        // for each layer we will create a separate list and add it.
        // for simplicity i can create a function and reuse it, having 2 values and output a result
        
        
        //print("before filling with loop value \(oneBigValuesList)")
        //print(oneBigValuesList.count)
        
        // if height of the list if equal to 1, then we have only
        
        // if width is one, it will output only one item i believe,
        
        for item in 0...(height - 1) {
            let product = createGradientList(leftValue: auroraHeightFirstLineValue[item],
                                             rightValue: auroraHeightLastLineValue[item],
                                             width: width)
            
            oneBigValuesList.append(contentsOf: product)
            layeredList.append(product)
            //print(product)
            //print("line")
        }

        
        /*
         indexation will go specific way, since each point represents a pixel we have a start pixel and end pixel
         longitude is a value from 0 to resolution - 1, as well as index, longitude is same
         index position will longitude * latitude (i think thats it for now)
         highest value will be resolution * resolution - 1
         512 * 512 = 262144 total items so last index will ne 262143
         
         since we have boundaries we can calculate all locations
         
         bottom latitude * left longitude = location of a first item
         top latitude - 1 * right longitude - 1 = location of a last item in rectangle
         fine tuning will be done later
         
         to calculate location in line, we can take initial value and add steps in range 0...width - 1
         to calculate for each new row, we would need to add a resolution value for each line, then follow with 1 step
         */
        

        var initialCoordinateRowValue: Double = 0 // how much increase by 512 to add to each start location. max value 511 only which would be 512 * 511
        
        if bottomLeftCoordinateLon == 0 {
            initialCoordinateRowValue = 0
        } else {
            initialCoordinateRowValue = bottomLeftCoordinateLon * Double(resolution)// was 512
        }
        
        
        let initialCoordinateValue = Int(bottomLeftCoordinateLat + initialCoordinateRowValue) // location of first aurora, its index on list
        
        var coordinateLine: [Int] = []
        
        coordinateLine.append(initialCoordinateValue) // first coordinate that will be in the list
  

        // check for width and height being 1, meaning there are no things to fill
        
        
        // check for height, if there any height, then items will be filled, if no, then there is only one value in column
        // check for width, if there any width then for each column add item to the width
        
        
        
        
        
        if width == 1 {
            
            // there are no width values that can be added, skip to height
            
        } else {
            
            var widthLine: [Int] = []
            
            // for each width value i will add inital value + res
            
            for column in 1...(width - 1) {
                // for each item add resolution*column
                
//                if initialCoordinateValue + (column * resolution) == 65536 {
                    
//                    print(inputRectangle)
//                    print(column)
//                    print("stop")
//                }
                
                widthLine.append(initialCoordinateValue + (column * resolution))
                
                
            }
            
            coordinateLine.append(contentsOf: widthLine) // we have our width value list
            
            //print(coordinateLine)
            //print("list")
            
        }
        
        
        if height == 1 {
            
            // end of function
            
        } else  {
            // for whole height append itearation of width for each height
            
            var newRow: [Int] = []
            let rowList = coordinateLine
            var appendingList: [Int] = []
            
            // cycle to fill height values
            
            var iterationAddition = 0
            
            for _ in 1...(height - 1) {
                
                iterationAddition = iterationAddition - 1
                
                for item in rowList {
                    
//                    if item + iterationAddition == 65536 {
                        
//                        print(inputRectangle)
//                        print(item)
//                        print("stop")
//                    }
                    newRow.append(item + iterationAddition)
                    
                }
                
                appendingList.append(contentsOf: newRow)
                
                //print(newRow)
                //print(coordinateLine)
                
                newRow = []
                //print("cycle")
            }

            //print()
            coordinateLine.append(contentsOf: appendingList)
            //print(coordinateLine)
            //print("height list")
           
            
        }
        

        
        outputValuesList = oneBigValuesList
        outuupIndexList = coordinateLine
        
//        if outputValuesList.count != coordinateLine.count {
//            print(outputValuesList)
//            print(coordinateLine)
//            print(inputRectangle)
//            print("this doesnt work")
//            print("check this out")
//        }

        /*
   
         
         Coordinate system in an array list
         
         resolution * resolution
         indexes 0...resolution - 1 = resolution items
         repeated resolution times, last index will be resolution * resolution - 1
         
         in this case of 512 * 512 = 262144 individuel pixels.
         
         task of this function is for each auroraRectange to create 2 lists, a list with values of aurora, and a list of indexes in resultion list per each value, with indexes of one list equating to items of anothrer lisrt.
         i will also later feed only nonzerr value, to make sure i dont waste any processing power. that should be an easy task
         
         
         to calculare a rectangle I would use a method of coordinates, and length with width value,
         
         1.0 0.0 0.0 0.0 1.0     1.0  1.0  1.0  1.0  1.0
         0.0 0.0 0.0 0.0 0.0     1.25 1.25 1.25 1.25 1.25
         0.0 0.0 0.0 0.0 0.0 =>  1.5  1.5  1.5  1.5  1.5
         0.0 0.0 0.0 0.0 0.0     1.75 1.75 1.75 1.75 1.75
         2.0 0.0 0.0 0.0 2.0     2.0  2.0  2.0  2.0  2.0
         
         calculation will go this way
         
         topLeftLat - bottmLeftLat = height - 1 = positions from topLeftLat to one before bottomLeftLAt, all lines that will be filled.
         
         topLeftLon - topRightLong = width - 1 = positions from left side to one before right side, all items on line will be filled  // exception item with index 359 per each line.
         
         if width - 1 or height - 1 != 0 = there are spots to fill
         
         amount of spots to fill - width / height - 1
         
         each row will have a calculated value with a formula: (topLeftAurora - bottomLeftAurora) / (height + 1)
         
         each line will be filled with
         
         topLeftAuroraValue, topLeftAuroraValue + ( 1 * topLeftAuroraValue / witdth - 1 )
         
         
         for height value i will firstly create a list for each line, (height - 1)
         
         then for each list i will append 1st value that will be calculated, or i can make it more complex? for now make it simpler.
         
         we would have some amount of lists, from 0...Some
         
         each first value will contain each start
         
         for value in range 0...(width - 1) {
         
         }
         
         */

        return (outputValuesList, outuupIndexList)
        
    }
    
    
    func calculateAmountOfAuroraValues(inputList: [Double]) -> [IndividualAuroraSpot] {
        
        /*
         To calculate what lists i would need to return, i would need to calculater boundaries for tile that will be represented.
         
         to calculate lists i would need 4 coordinates, bottomLeftLat, bottomLeftLon, bottomRightLon and topLeftLat
         
         then i would need to get only lists that fall into that boundaries, as well as temp print amount of items.
         I would need to clacluate based on already converted to mercator list.
         
         using switch? since i would need to go through whole list that might take a while, find a quicker way?
         
         creating separate lists? like 4, then check for location 0-180 / 180-360 and -85-0 / 0 - 85 since it would ne devided this way based on tile drawing anyway.
         
         Maybe looking through actual coordinates won't take as long, still, would be a good idea to optimize lists,
         to make sure I can save some time.
         
         filter only aurora list, then create rectangles, then append them to a list
         create a condition that will check for inbetween values, if inbetween, create values after ratio based on border values
         
         example
         
         let say we have 80.100 -> 80.200 latitude, then it means we will take increments anf apply to value from 80 - 81
         0...100%, 0.1 -> 0.2, meaning if we will get aurora 7...8, we will recieve value 7.1...8.1.
         then proceed with gradient and check for specifics since bitmap can show values in range 0...255.
         
        */
        
        let outputList: [IndividualAuroraSpot] = []
        
        // in case if there are only 1 aurora, ony 1 will be added to the list
        
        
        return outputList
    }

    
    
    

    // This function can be used to get tiles from tilePathURL override to calculate needed coordinates if i can reverse this function
    // then with tiles info provided by pathfinder i can start calculating it.
    
    // not implemented!
    
    func transformCoordinate(_ xTile: Int, _ yTile: Int, withZoom zoom: Int) -> [Double] {
        
        /*
         
         Tile numbers range from 0 to 2^zoom level. so each tile has a coordinate range from one side to another. Thats what i need.
         
         for x its a number fom 0...360, and a tile number would be a range with increments of zoom level. (describe better)
         
         for example if we have zoom 4, and tile number 11,
         it means that our coordinate range would be (10 * (360 / 2^zoom))...(11 * (360 / 2^zoom)) // ???
         
         maybe subtract some amount would be needed, but im not sure yet, leave for later,
         
         same kinda works for latitude, if it is already mercator translated tho, that can make calculations easy,
         if not - welp. Would have to figure this out.
         
         however i can just get coordinates and then translate them to mercator? that could work and save me some headache
         
         after translation i would need to correctly translate values to a 256x256 grid with correct ratios
         
         
         */
        var outputList: [Double] = []
        
        let zoomNum = Int(pow(2.0, Double(zoom)))
        
        let xCoordinateStart = Double(xTile * (360 / zoomNum))
        let xCoordinateFinish = Double((xTile + 1) * (360 / zoomNum))
        
        // try with 171 anyways
        
        let yCoordinateStart = Double(yTile * (180 / zoomNum)) // was 171
        let yCoordinateFinish = Double((yTile + 1) * (180 / zoomNum))
        
        /*
        // for looking up a tile number with zoom level
        let tileX = Int(floor((longitude + 180) / 360.0 * pow(2.0, Double(zoom))))
        let tileY = Int(floor((1 - log( tan( latitude * Double.pi / 180.0 ) + 1 / cos( latitude * Double.pi / 180.0 )) / Double.pi ) / 2 * pow(2.0, Double(zoom))))
        
        return (tileX, tileY)
         */
        
        outputList.append(xCoordinateStart)
        outputList.append(xCoordinateFinish)
        outputList.append(yCoordinateStart)
        outputList.append(yCoordinateFinish)
        
//        print("current xTile is \(xTile)")
//        print("current yTile is \(yTile)")
//        print("current zoom is \(zoom)")
//        print(outputList)
        /*
        if xTile == 0 && yTile == 0 {
            print("lmao")
        }
        
        if yCoordinateStart > 155 {
            print("current xTile is \(xTile)")
            print("current yTile is \(yTile)")
            print("current zoom is \(zoom)")
            print(outputList)
            print("lmao")
        }
        */
        let product = tileToCoordinate(xTile, yTile, zoom: zoom)
        
        //print(product)
        
        // for resulution pass 2^zoom
        
        /*
        let startList = latLonToMercatonSecond(inputLatitude: yCoordinateStart,
                                               inputLongitude: xCoordinateStart,
                                               resolution: zoomNum)
        
        let finishList = latLonToMercatonSecond(inputLatitude: yCoordinateFinish,
                                                inputLongitude: yCoordinateFinish,
                                                resolution: zoomNum)
        var convertedList: [Double] = []
        
        convertedList.append(startList.outputLongitude)
        convertedList.append(finishList.outputLongitude)
        convertedList.append(startList.outputLatitude)
        convertedList.append(finishList.outputLatitude)
        
        */
        /*
        if finishList.outputLatitude.isNaN {
            print(convertedList)
            print("nanDetected")
        }
        */
        
        return outputList
    }
}



/*
 
 
 var firstItemInList = true
 var firstLine = true
 
 for item in 0...(width - 1) {
     var originalFlip: [IndividualAuroraSpot] = []
     
     // pixels to fill =/= index, figure this out correctly
     
//            print("start of column")
//            print("this is how many items i would fill \(indexHeight.count)")
     
     // append first item with index 0, then just append with more
     /*
     if firstItemInList {
         // furst item in a total list
         // otherwise index will be out of range
         var firstcoordinate = IndividualAuroraSpot(longitude: 0,
                                                    latitude: 0,
                                                    aurora: inputList[item].aurora)
         
         originalFlip.append(firstcoordinate)
         firstItemInList = false
         
     } else {
         // first item will always have a 0 in Latitude, last item will be 255
         // first longitude
         
         var firstcoordinate = IndividualAuroraSpot(longitude: Double(longitudeIndex),
                                                    latitude: 0,
                                                    aurora: inputList[item].aurora)
         
         originalFlip.append(firstcoordinate)
         
     }
      */
     
     
     
     for latitude in 0...(height - 1) {
         
//                if firstLine {
//                    longitudeIndex = 1
//                }
         
         
         let newCorrdinate = IndividualAuroraSpot(longitude: Double(longitudeIndex),
                                                  latitude: Double(latitudeIndex),
                                                  aurora: inputList[item].aurora)
         
         // subtract one after adding zero, so it wont put things out of bound and restructure so it always adds a last item.
         
         
         latitudeIndex = latitudeIndex + Int(heightIndexList[latitude])
         
         
         print(latitudeIndex)
         
         // this might be wrong, look up later.!!!!
         
         // testList.append(newCorrdinate)
         originalFlip.append(newCorrdinate)
         
     }
 
 */



/*
 
 func createGradientRectangle(inputRectangle: AuroraCoordinateRectangle, resolution: Int) -> (valueList: [Double], indexList: [Int]) {
     var outputValuesList: [Double] = []
     var outuupIndexList: [Int] = []
     
     let bottomLeftCoordinateLat = inputRectangle.coordinateList[0]
     let bottomLeftCoordinateLon = inputRectangle.coordinateList[1]
     let bottomRightCoordinateLon = inputRectangle.coordinateList[2]
     let topLeftCoordinateLat = inputRectangle.coordinateList[3]
     
     let auroraBottomLeftCorner: Double = inputRectangle.auroraList[0] // 0
     let auroraBottomRightCorner: Double = inputRectangle.auroraList[1] // 0
     let auroraTopLeftCorner: Double = inputRectangle.auroraList[2] // 1
     let auroraTopRightCorner: Double = inputRectangle.auroraList[3] // 1
     
     
//        print(inputRectangle)
     
     // largest value should ne 255.
//        print("input trianlge")
     
     
     /*
      BEFORE CHANGES
      
      var bottomLeftCoordinateLat = inputRectangle.coordinateList[0]
      var bottomLeftCoordinateLon = inputRectangle.coordinateList[1]
      var bottomRightCoordinateLon = inputRectangle.coordinateList[2]
      var topLeftCoordinateLat = inputRectangle.coordinateList[3]
      
      var auroraBottomLeftCorner: Double = inputRectangle.auroraList[0]
      var auroraBottomRightCorner: Double = inputRectangle.auroraList[1]
      var auroraTopLeftCorner: Double = inputRectangle.auroraList[2]
      var auroraTopRightCorner: Double = inputRectangle.auroraList[3]
      
      
      
      */
     
     
     let height = abs(Int(topLeftCoordinateLat - bottomLeftCoordinateLat))
     let width = abs(Int(bottomLeftCoordinateLon - bottomRightCoordinateLon))
     
     var oneBigValuesList: [Double] = []
 
     
     var auroraHeightFirstLineValue: [Double] = []
     var reversedArray: [Double] = []
     
     auroraHeightFirstLineValue.append(auroraBottomLeftCorner) // adding first aurora value
     
     var auroraHeightLastLineValue: [Double] = []
     var reversedArrayRight: [Double] = []
     
     auroraHeightLastLineValue.append(auroraBottomRightCorner)
     
     let auroraDifferenceLeft = abs(auroraBottomLeftCorner - auroraTopLeftCorner)
     var smallerLeft = 0.0
     
     if auroraBottomLeftCorner > auroraTopLeftCorner {
         smallerLeft = auroraTopLeftCorner
     } else {
         smallerLeft = auroraBottomLeftCorner
     }
     

     
     if height == 1 {
         // if there are no differences in height, next value is next avaliable value
         
         auroraHeightFirstLineValue.append(auroraTopLeftCorner)
         auroraHeightLastLineValue.append(auroraTopRightCorner)
         
         // then we check for any width, if there is any, then we can make wide line, if not = we create a single dot
         
         // its rectangle by side to side
         
         // if height is equal to 1, meaning that i would need to add only 1 lane, what to do?
         
         
     } else {
         // rest of code
         
         for item in 0...(height - 1) { // for each cell, add incremental step to a value // was 1
             
             var appendingValue: Double = 0
             
             if auroraDifferenceLeft == 0 { // if there are no difference, will it with Bottom value since they all same.
                 appendingValue = auroraBottomLeftCorner
             } else {
                 appendingValue = Double((Double(item) * auroraDifferenceLeft) / Double(height)) + smallerLeft
             }
             reversedArray.append(appendingValue)
             // item is a step from 0 to last, i will iuse it as increments
         }
         
         if auroraBottomLeftCorner > auroraTopLeftCorner {
             reversedArray.reverse()
         }
         
         auroraHeightFirstLineValue.append(contentsOf: reversedArray)
                 
         // repeat same with last values so we know how to increment per each list
                        
         let auroraDifferenceRight = abs(auroraBottomRightCorner - auroraTopRightCorner)
         var smallerRight = 0.0
         
         
         if auroraBottomRightCorner > auroraTopRightCorner {
             smallerRight = auroraTopRightCorner
         } else {
             smallerRight = auroraBottomRightCorner
         }
         
         for item in 0...(height - 1) { // for each cell, add incremental step to a value // was one
             var appendingValue: Double = 0
             
             if auroraDifferenceRight == 0 { // if there are no difference, will it with Bottom value since they all same.
                 appendingValue = auroraBottomRightCorner
             } else {
                 appendingValue = Double((Double(item) * auroraDifferenceRight) / Double(height)) + smallerRight
             }
             reversedArrayRight.append(appendingValue)
             // item is a step from 0 to last, i will iuse it as increments
         }
         
         if auroraBottomRightCorner > auroraTopRightCorner { // works
             reversedArrayRight.reverse()
         }
         
         auroraHeightLastLineValue.append(contentsOf: reversedArrayRight)
     }
     
     func createGradientList(leftValue: Double, rightValue: Double, width: Int) -> [Double] {
         var gradientList: [Double] = []
         var productArray: [Double] = []
         
         
         // start with appending left value
         gradientList.append(leftValue)
         
         // define which is larger
         
         let differenceValue = abs(leftValue - rightValue)
         var smallerValue = 0.0
         
         if leftValue > rightValue {
             smallerValue = rightValue
         } else {
             smallerValue = leftValue
         }
         
         if width - 1 == 0 {
             
             // if width is 0, then we need to return, since we already have a product which is first item in line
             
         } else {
             for item in 1...(width - 1) { // was 1
                 var appendingValue = 0.0
                 
                 if differenceValue == 0 {
                     appendingValue = leftValue
                 } else {
                     appendingValue = Double(Double(item) * differenceValue / Double(width)) + smallerValue
                 }
                 
                 
                 productArray.append(appendingValue)
             }
         }
         
         
         if leftValue > rightValue {
             productArray.reverse()
         }
         
         gradientList.append(contentsOf: productArray)
         return gradientList
     }
     
     
     
     
     
     // now when we have a list, we can create a new set of lists for each value in this list
     
     var layeredList: [[Double]] = []

     
     for item in 0...(height - 1) {
         let product = createGradientList(leftValue: auroraHeightFirstLineValue[item],
                                          rightValue: auroraHeightLastLineValue[item],
                                          width: width)
         
         oneBigValuesList.append(contentsOf: product)
         layeredList.append(product)
         //print(product)
         //print("line")
     }



     var initialCoordinateRowValue: Double = 0
     
     if bottomLeftCoordinateLon == 0 {
         initialCoordinateRowValue = 0
     } else {
         initialCoordinateRowValue = bottomLeftCoordinateLon * Double(resolution)// was 512
     }
     
     
     let initialCoordinateValue = Int(bottomLeftCoordinateLat + initialCoordinateRowValue) // location of first aurora, its index on list
     
     var coordinateLine: [Int] = []
     
     coordinateLine.append(initialCoordinateValue) // first coordinate that will be in the list

     
     if width == 1 {
         
         // there are no width values that can be added, skip to height
         
     } else {
         
         var widthLine: [Int] = []
         
         // for each width value i will add inital value + res
         
         for column in 1...(width - 1) {
             // for each item add resolution*column
             
             widthLine.append(initialCoordinateValue + (column * resolution))
             
         }
         
         coordinateLine.append(contentsOf: widthLine) // we have our width value list
         
         //print(coordinateLine)
         //print("list")
         
     }
     
     
     if height == 1 {
         
         // end of function
         
     } else  {
         // for whole height append itearation of width for each height
         
         var newRow: [Int] = []
         let rowList = coordinateLine
         var appendingList: [Int] = []
         
         // cycle to fill height values
         
         var iterationAddition = 0
         
         for _ in 1...(height - 1) {
             
             iterationAddition = iterationAddition - 1 // was + 1
             
             for item in rowList {
                 newRow.append(item + iterationAddition)
                 
             }
             
             appendingList.append(contentsOf: newRow)
             
             //print(newRow)
             //print(coordinateLine)
             
             newRow = []
             //print("cycle")
         }

         //print()
         coordinateLine.append(contentsOf: appendingList)
         //print(coordinateLine)
         //print("height list")
        
         
     }
     
//        print(inputRectangle)
//        print(oneBigValuesList)
//        print(oneBigValuesList.count)
//        print(coordinateLine)
//        print(coordinateLine.count)
     
     outputValuesList = oneBigValuesList
     outuupIndexList = coordinateLine

     return (outputValuesList, outuupIndexList)
     
     
 }
 
 
 */
