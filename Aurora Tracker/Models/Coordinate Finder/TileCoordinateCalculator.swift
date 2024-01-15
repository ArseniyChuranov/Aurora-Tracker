//
//  TileCoordinateCalculator.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 10/25/23.
//

import Foundation

class TileCoordinateCalculator {
    
    // Function to calculate longitude for specific zoom and return it's location.
    
    func calculateLongitude(inputLongitude: Double, coordinateZoom: Int) -> Double {
        
        let mapSide = Double(coordinateZoom)
        
        var resolution = Double(pow(2, mapSide))
        
        resolution = 255 * resolution // was 256
        
        let outputLongitude = inputLongitude * (resolution / 360)
        
        return outputLongitude
    }
    
    // rotate list
    
    func rotateList(inputList: [IndividualAuroraSpot], height: Int, width: Int) -> [IndividualAuroraSpot] {
        
        // Calculate to which direction i will rotate the list, account for all sizes, min is 4
        // output list should start with topLeft value, min longitude, max latitude.
        // Each line should contain same latitude, different longitude values
        
        
        var outputList: [IndividualAuroraSpot] = []
        
        var rowList: [IndividualAuroraSpot] = []
        var itemIndex = height - 1 // was 0
        
        // each side is equals to amount of elements i have per row, and index for next row position
        
        for column in 1...height {
            // cycle through each side, creating a row
            // secont loop will come here
            
            for _ in 0...(width - 1) {
                // collect items per each row
                rowList.append(inputList[itemIndex])
                itemIndex = itemIndex + height
            }
            
            itemIndex = (height - 1) - column
            outputList.append(contentsOf: rowList)
            rowList = []
        }
        
        return outputList
    }
    
    
    /*
     
     This function takes zoom and input latitude, then calculates it location based on overall resolution.
     This information is useful to calculate ratio between other values to create a more accurate representation on the map
     
     */
    
    func calculateLatitude(inputCordinate: Double, coordinateZoom: Int) -> Double {
        
        let mapSide = Double(coordinateZoom) // custom square resolution
        
        var resolution = Double(pow(2, mapSide))
        
        // Separating into two values and calculating this way got me good results so far.
        
        let newResolution = resolution * 255 // thats a weird solution
        
        resolution = 256 * resolution // was 255, changed to 256
        
        let latRad = inputCordinate * Double.pi / 180
        let mercN = log(tan((Double.pi / 4) + (latRad / 2)))
        
        let outputLatitude = (resolution / 2) - (newResolution * mercN / (2 * Double.pi))
        
        return outputLatitude
    }
    
    
    
    // function to create coordinates for new tile. Accounts for Mercator projection
    
    func spreadCoordinatesForRes(minValue: Double,
                                 maxValue: Double,
                                 dimension: Int,
                                 coordinateType: String,
                                 zoom: Int) -> [Double] {
        
//        let start = BasicTimer().startTimer()
        
        if dimension == 0 {
            print(maxValue)
            print(minValue)
        }
        
        // Later i would need to rework this whole function.
        
        var experimentalListRounded: [Double] = []

        
        /*
         
         I would need to create an elegant and simple tactics to translate coordinate borders to correct coordinate
            on 256 x 256 tile
         
         First would be to Use function with mercator projections for both longitude and latitude
         
         first coordinate will be 0, last coordinate will be 255
         
         
         */
        
        
        var differenceList: [Double] = []

        // lazy way to get a result
        
        let startCorridinate = minValue.rounded(.down)
        let finishCorridnate = maxValue.rounded(.up)
        
        let difference = Int(abs(finishCorridnate - startCorridinate))
        
        var listStartIndex = startCorridinate
        var wholeCoordinateList: [Double] = []
        
        var startLongitudeListIndex = startCorridinate
        var wholeLongitudeCoordinateList: [Double] = []
        
        var longitudeMercatorList: [Double] = []
        var latitudeMercatorList: [Double] = []
        
        var experimentalLongitudeListRounded: [Double] = []
 
  
        if coordinateType == "Latitude" {
            
            // for latitude use a function to calculate ratios for latitude values,
            // then return a list thaty will represent pixels.
            
            for _ in 0...difference {
                wholeCoordinateList.append(listStartIndex)
                listStartIndex = listStartIndex + 1
                
            }
            
            wholeCoordinateList[0] = minValue
            wholeCoordinateList[wholeCoordinateList.count - 1] = maxValue
            
            for coordinate in wholeCoordinateList {
                let lat = calculateLatitude(inputCordinate: coordinate, coordinateZoom: zoom)
                latitudeMercatorList.append(lat)
            }

            var roundedValuesSimple: [Double] = []
            
            for item in 0...latitudeMercatorList.count-2 {
                let appendValue = latitudeMercatorList[item] - latitudeMercatorList[item + 1]
                differenceList.append(appendValue)
                roundedValuesSimple.append(appendValue.rounded())
            }
            
            var sumOfStuff = 0.0
            
            for item in differenceList {
                sumOfStuff = sumOfStuff + item
            }
            
            var possiblyPixelList: [Double] = []
            var possiblyRoundedPixelList: [Double] = []
            
            var initialValue = 0.0
            
            for item in differenceList {
                initialValue += item
                possiblyPixelList.append(initialValue)
                possiblyRoundedPixelList.append(initialValue.rounded())
            }
            
            var experimentalList: [Double] = []

            
            for item in latitudeMercatorList {
                let maybeSolution = latitudeMercatorList[0] - item
                experimentalList.append(maybeSolution)
                experimentalListRounded.append(maybeSolution.rounded())
            }
            
            if experimentalListRounded[1] == 0.0 {
                experimentalListRounded[1] = 1.0
            }
            
            // This is not good, and should be remade.
            
            if experimentalListRounded.count > 3 {
                if experimentalListRounded[experimentalListRounded.count - 2] >= 255.0 {
                    
                    experimentalListRounded[experimentalListRounded.count - 2] = 254.0
                }
            }
        }
        
        
        // Longitude method does't work properly for me so far. I would need to figure this out later.

        if coordinateType == "Longitude" {
            
            // process longitude values according to ratios.
            
            for _ in 0...difference {
                wholeLongitudeCoordinateList.append(startLongitudeListIndex)
                startLongitudeListIndex += 1
            }
            
            wholeLongitudeCoordinateList[0] = minValue
            wholeLongitudeCoordinateList[wholeLongitudeCoordinateList.count - 1] = maxValue
            
            for coordinate in wholeLongitudeCoordinateList {
                let lon = calculateLongitude(inputLongitude: coordinate, coordinateZoom: zoom)
                longitudeMercatorList.append(lon)
            }
            
            for item in 0...longitudeMercatorList.count-2 {
                let appendValue = abs(longitudeMercatorList[item] - longitudeMercatorList[item + 1])
                differenceList.append(appendValue)
            }
            
            for item in longitudeMercatorList {
                let maybeSolution = abs(longitudeMercatorList[0] - item)
                // experimentalList.append(maybeSolution)
                experimentalLongitudeListRounded.append(maybeSolution.rounded())
            }
            
//            print(longitudeMercatorList)
//            print(experimentalLongitudeListRounded)
//            print()

        }
        
        // Function below needs to be included so far, will be removed later.

        
        var outputList: [Double] = []

        let widthIncrements = 255.0 / abs(maxValue - minValue) // pixels per whole width of a tile // was 256
        
        let startValueProportion = abs(minValue - minValue.rounded(.up))
        let lastValueProportion = abs(maxValue - maxValue.rounded(.down))
        let wholeNumersAmount = abs(maxValue.rounded(.down) - minValue.rounded(.up))


        var firstPixelWidth = startValueProportion * widthIncrements
        var lastPixelWidth = lastValueProportion * widthIncrements
        var wholePixels = wholeNumersAmount * widthIncrements
        

        
        firstPixelWidth.round()
        lastPixelWidth.round()
        wholePixels.round()
        
        // var itemsNum = 0
        var addLastIndex = true
        
        // change dimension to 4 cases as well.
        
        // older method, was calculating equal distances, not acounting for mercator distortion.
        // still used for longitude calculations. Looks complex, because it is.
        
        if dimension == 2 {
            
            // This means there are no values to fill.
            
        } else {
            var itemsToFill = dimension - 2 // 0.0 <stuff to fill> // was -2, should remade to be -1
            var fillLast = false
            
            if firstPixelWidth != 0 {
                outputList.append(firstPixelWidth)
                itemsToFill = itemsToFill - 1
            }
            
            if lastPixelWidth != 0 {
                itemsToFill = itemsToFill - 1
                fillLast = true
            }
            
            var leftover: Double = 0.0

            // if itemstoFill < 1, do a thing
            
            if itemsToFill > 0 {
                
                // if anything to fill, fill in
                
                // if it's only 1 item,
                
                if itemsToFill == 1 {
                    
                    let wholePixel = wholePixels / Double(itemsToFill + 1)
                    
                    leftover = leftover + (wholePixel - wholePixel.rounded(.down))
                    
                    outputList.append(wholePixel + leftover)
                    
                    leftover = 0.0
                    
                } else {
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

                
            } else {

                if itemsToFill > -1 {
                    outputList.append(wholePixels)
                } else {
                    outputList = []
                    
                    outputList.append(firstPixelWidth + wholePixels)
                    
                }

                addLastIndex = false
                
            }
            
            if fillLast {
                outputList.append(lastPixelWidth)
            }
        }

        
        var actualIndexes: [Double] = []
        var indexAmount = 0.0
        
        actualIndexes.append(0.0)
        
        if dimension > 2 {
            for index in outputList {
                //output list will always have correct num of incements
                indexAmount = indexAmount + index
                actualIndexes.append(indexAmount)
            }
        }
        

        
        if addLastIndex == true {
            actualIndexes.append(255.0)
        } else {
            var lastValue = actualIndexes[actualIndexes.count - 1]
            lastValue = lastValue - 1.0
            actualIndexes[actualIndexes.count - 1] = 255.0
        }
        
        
        if dimension != actualIndexes.count {
            print("first pixel rounded \(firstPixelWidth)")
            print("whole pixels rounded \(wholePixels)")
            print("last pixel rounded \(lastPixelWidth)")
            print("check for val")
    
        }
        
        

        
        if coordinateType == "Longitude" {
//            print("Experimental Longitude List")
//            print(experimentalLongitudeListRounded)
//            print(experimentalLongitudeListRounded.count)
//            print("Actual Indexes")
//            print(actualIndexes)
//            print(actualIndexes.count)
            
            differenceList = []
            
            for item in 0...longitudeMercatorList.count-2 {
                let appendValue = longitudeMercatorList[item] - longitudeMercatorList[item + 1]
                differenceList.append(appendValue)
            }
            //let count = differenceList.reduce(0, {x, y in x + y})
            //print(count)
            
            if experimentalLongitudeListRounded.count != actualIndexes.count {
                
                experimentalLongitudeListRounded.remove(at: experimentalLongitudeListRounded.count - 2)
                print()
            }
            
            // print("Longitude")
            
            actualIndexes = experimentalLongitudeListRounded
        }
        
        if coordinateType == "Latitude" {
            
//            print("Actual Indexes")
//            print(actualIndexes)
//            print(actualIndexes.count)
            
//            print("Experimental Latitude List")
//            print(experimentalListRounded)
//            print(experimentalListRounded.count)
            
            // print("Latitude")
            
            actualIndexes = experimentalListRounded
        }
        /*
        
        if coordinateType == "Longitude" {
            actualIndexes = experimentalLongitudeListRounded
        }
         */
        
//        BasicTimer().endTimer(start, functionName: "spreadCoordinatesForRes")
        
        return actualIndexes
    }
    
    // used to append elements for pixelCount items to return actual aurora positions.
    
    // not implemented
    
    func createIndexes(inputList: [Double]) -> [Double] {
        var outputList: [Double] = []
        var indexAmount = 0.0
        
        outputList.append(0.0)
        
        for index in inputList {
            //output list will always have correct num of incements
            indexAmount = indexAmount + index
            outputList.append(indexAmount)
        }
        
        outputList.append(255.0)
        
        return outputList
    }

 
}
