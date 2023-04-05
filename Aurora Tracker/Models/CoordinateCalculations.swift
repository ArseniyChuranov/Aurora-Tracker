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
    
    // All updates in future will simplify each method.
    // So far each func does multiple simple things.
    
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
    
    // For each tile resturns corner values of requested tile.
    
    func tileToCoordinate(_ tileX: Int, _ tileY: Int, zoom: Int) -> ([Double]) {

        var outputList: [Double] = [] // bottomLeftLat, bottomLeftLon, bottomRightLon, topLeftLat
        
        let res: Double = pow(2, Double(zoom))
        
        // do something with list? to shift all auroras

        let bottomLeftLat = atan( sinh (.pi - (Double(tileY) / res) * 2 * Double.pi)) * (180.0 / .pi)
        let bottomLeftLon = (Double(tileX) / res) * 360.0 // - 180.0
        let bottomRightLon = (Double(tileX + 1) / res) * 360.0 // - 180.0
        let topLeftLat = atan( sinh (.pi - (Double(tileY + 1) / res) * 2 * Double.pi)) * (180.0 / .pi)
        
        outputList.append(bottomLeftLat)
        outputList.append(bottomLeftLon)
        outputList.append(bottomRightLon)
        outputList.append(topLeftLat)

        
        return outputList
        
    }
    
    // function to create extra spaces for outOfBound values that would be repearted, will help to create a simpler function.
    // so far obsolete, not implemented
    // can be useful if i will have more lists in future
    
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
                              inputAuroraList: [IndividualAuroraSpot],
                              zoom: Int) -> (inputList: [IndividualAuroraSpot],
                                             width: Int,
                                             height: Int,
                                             indexWidth: [Double],
                                             indexHeight: [Double]) {
        

        var latitudeList: [IndividualAuroraSpot] = []
        
        // actual corner coordinates
        
        let topLatitude = inputTileCoordinateList[0]
        let bottomLatitude = inputTileCoordinateList[3]
        let maxLongitude = inputTileCoordinateList[2]
        let minLongitude = inputTileCoordinateList[1]
        
        // Outer boundaries for latitude and longitude describing a larger square where actual coordinates fit
        
        let celingLatitudeValue = topLatitude.rounded(.up)
        let floorLatitudeValue = bottomLatitude.rounded(.down)
        let startLongitudeValue = minLongitude.rounded(.down)
        let finishLongitudeValue = maxLongitude.rounded(.up)
        
//        let topLatitudeDiff = abs(celingLatitudeValue - topLatitude) // difference between celing and input value
//        let bottomLatitudeDiff = abs(bottomLatitude - floorLatitudeValue) // difference between bottom and floor
//        let rightLongitudeDiff = abs(startLongitudeValue - minLongitude) // difference between start and right longitude
//        let leftLongitudeDiff = abs(maxLongitude - finishLongitudeValue) // difference between end and left latitude
        
        // dimensions of a square
        
        var height = 0
        var width = 0
        
        // indexes will pass a number of pixels used to fill in distances between coordinates
        
        var indexWidth: [Double] = []
        var indexHeight: [Double] = []
        
        // differences between border values and actual values, used to create an accurate aurora value
        
        let differenceTopLat = topLatitude - topLatitude.rounded(.down)
        let differenceBottomLat = bottomLatitude - bottomLatitude.rounded(.down)
        let differenceLeftLon = minLongitude - minLongitude.rounded(.down)
        let differenceRightLon = maxLongitude - maxLongitude.rounded(.down)
        
        //        let latitudeSquaresCount = (topLatitude.rounded(.up) - bottomLatitude.rounded(.down))
        //        let longitudeSquaresCount = (maxLongitude.rounded(.up) - minLongitude.rounded(.down))
        
        var initialList: [IndividualAuroraSpot] = []
        var initialBackupList: [IndividualAuroraSpot] = []
        
        var allChangedLatitudeAuroraValues: [Double] = []
        var allChangedLongitudeAuroraValues: [Double] = []
        
        
        var updatedLatitudeAuroraValues: [IndividualAuroraSpot] = []
        var updatedLongitudeAuroraValues: [IndividualAuroraSpot] = []
   
        
        for aurora in inputAuroraList {

            
            if aurora.longitude >= startLongitudeValue && aurora.longitude <= finishLongitudeValue {
                if aurora.latitude >= floorLatitudeValue && aurora.latitude <= celingLatitudeValue {
                    latitudeList.append(aurora)
                    initialList.append(aurora)
                    initialBackupList.append(aurora)
                }
            }
        }

        
        let widthCount = latitudeList[0].latitude
        let heightCount = latitudeList[0].longitude
        
        for item in latitudeList {
            
            // same latitude = width
            
            if item.latitude == widthCount {
                width = width + 1
            }
            
            // same longitude = height
            
            if item.longitude == heightCount {
                height = height + 1
            }
        }
        
        
        var allChangedBottomValues: [Double] = []
        
        
        var topIndex = height - 1
        var bottomIndex = 0
        
        for _ in 1...width {
            
            // this loop changes latitude values.
            // calculate top and bottom aurora.
            
            let bottomAuroraCoordinate = latitudeList[bottomIndex]
            var bottomAuroraValue = bottomAuroraCoordinate.aurora
            
            let nextAuroraValue = latitudeList[bottomIndex + 1].aurora
            
            // calculate new aurora difference applied to an aurora
            
            let bottomAuroraDifference = bottomAuroraValue - nextAuroraValue
            let changedBottomValue = bottomAuroraDifference * differenceBottomLat
            bottomAuroraValue = bottomAuroraValue - changedBottomValue // nextAuroraValue + changedBottomValue
            
            allChangedLatitudeAuroraValues.append(bottomAuroraValue)
            
            allChangedBottomValues.append(bottomAuroraValue)
            
            let newLeftAurora = IndividualAuroraSpot(longitude: bottomAuroraCoordinate.longitude,
                                                     latitude: bottomLatitude,
                                                     aurora: bottomAuroraValue)
            
            updatedLatitudeAuroraValues.append(newLeftAurora)
            
            /*
            if bottomAuroraValue != 0 {
                print(initialList)
                
                print(latitudeList[bottomIndex])
                print(latitudeList[bottomIndex + 1])
                
                print(initialList[bottomIndex])
                print(initialList[bottomIndex + 1])
                print(bottomAuroraValue)
                
                print()
            }
            */
            
            let topCoordinateAurora = latitudeList[topIndex]
            var topAuroraValue = topCoordinateAurora.aurora
            let previousAuroraValue = latitudeList[topIndex - 1].aurora
            
            let topAuroraDifference = topAuroraValue - previousAuroraValue
            let changedTopValue = topAuroraDifference * differenceTopLat
            topAuroraValue = topAuroraValue - changedTopValue // previousAuroraValue + changedTopValue
            
            allChangedLatitudeAuroraValues.append(topAuroraValue)

            let newRightAurora = IndividualAuroraSpot(longitude: topCoordinateAurora.longitude,
                                                      latitude: topLatitude,
                                                      aurora: topAuroraValue)
            
            updatedLatitudeAuroraValues.append(newRightAurora)
            
            latitudeList[bottomIndex] =  newLeftAurora
            latitudeList[topIndex] = newRightAurora
            
            topIndex = topIndex + (height)
            bottomIndex = bottomIndex + (height)
            
        }
        
        var rightIndex = height * (width - 1)
        var leftIndex = 0
        
        
        for _ in 1...(height) {
            
            // declare aurora coordinate and aurora value
            
            // replaced latitudelist with initialList
            
            // need to get it back
            
            let leftAuroraCoordinate = initialList[leftIndex]
            var leftAuroraValue = leftAuroraCoordinate.aurora
            let nextLeftAuroraValue = initialList[leftIndex + height].aurora
            
            
            let leftAuroraDifference = leftAuroraValue - nextLeftAuroraValue
            let changedLeftValue = leftAuroraDifference * differenceLeftLon // leftLon, since we comparing edge values
            leftAuroraValue = leftAuroraValue - changedLeftValue // changedLeftValue + nextLeftAuroraValue
            
            // create a new individual spot with a new value
            
            allChangedLongitudeAuroraValues.append(leftAuroraValue)
            
            let newBottomAurora = IndividualAuroraSpot(longitude: minLongitude,
                                                       latitude: latitudeList[leftIndex].latitude,
                                                       aurora: leftAuroraValue)
            
            updatedLongitudeAuroraValues.append(newBottomAurora)
            
            // declare aurora coordinate and new aurora value
            
            
            let topRightCoordinate = initialList[rightIndex]
            var rightAuroraValue = topRightCoordinate.aurora
            let PreviousRightAurora = initialList[rightIndex - height].aurora
            
            let rightAuroraDifference = rightAuroraValue - PreviousRightAurora
            let changedRightValue = rightAuroraDifference * differenceRightLon // rightLon? change to lat
            rightAuroraValue = rightAuroraValue - changedRightValue // changedRightValue + PreviousRightAurora
            
            allChangedLongitudeAuroraValues.append(rightAuroraValue)
            /*
            if rightAuroraValue != 0 {
                print(latitudeList[rightIndex])
                print(latitudeList[rightIndex - height])
                
                
                print(rightIndex)
                print(rightIndex - height)
                
                print(latitudeList)
                
                
                print(rightAuroraValue)
                print(PreviousRightAurora)
                
                print()
            }
            */
            let newTopAurora = IndividualAuroraSpot(longitude: maxLongitude,
                                                    latitude: latitudeList[rightIndex].latitude,
                                                    aurora: rightAuroraValue)
            
            updatedLongitudeAuroraValues.append(newTopAurora)
            
            latitudeList[leftIndex] = newBottomAurora
            latitudeList[rightIndex] = newTopAurora
            
            // we are changing first width and last width values, so BOTTOM and TOP of a rectangle
            
            leftIndex = leftIndex + 1
            rightIndex = rightIndex + 1
        }
        
        // returns latitude list
        
        // all calculations done above.
        
        // make a corner value update
        
        var cornerPixelList: [Int] = []
//        var initialPixelLst: [Int] = []
        
        var cornerAuroraValues: [IndividualAuroraSpot] = []
        var initialCornerAuroraValues: [IndividualAuroraSpot] = []
        
        cornerPixelList.append(contentsOf: calculateCornerValuesIndexes(inputWidth: width, inputHeight: height))
        
        // creates a rectangle for each corner, not necessary for now.
        
        func calculateCornerValuesIndexes(inputWidth: Int, inputHeight: Int) -> [Int] {
            var outputIndexesList: [Int] = []
            // calculations will be dont on order, to form 4 indexes. each 4 sets will represent
            // rectangle with bottomLeft, topLeft, bottomRight, topRight sides,
            
            outputIndexesList.append(0)
            outputIndexesList.append(1)
            outputIndexesList.append(height)
            outputIndexesList.append(height + 1)
            
            outputIndexesList.append(height - 2)
            outputIndexesList.append(height - 1)
            outputIndexesList.append(height + height - 2)
            outputIndexesList.append(height + height - 1)
            
            let lastIndex = (height * width) - 1
            
            
            outputIndexesList.append(lastIndex - (2 * height) + 1)
            outputIndexesList.append(lastIndex - (2 * height) + 2)
            outputIndexesList.append(lastIndex - height + 1)
            outputIndexesList.append(lastIndex - height + 2)
            
            outputIndexesList.append(lastIndex - height - 1)
            outputIndexesList.append(lastIndex - height)
            outputIndexesList.append(lastIndex - 1)
            outputIndexesList.append(lastIndex)
            
            return outputIndexesList
        }

        // create values with indexes, process them?
        
        for item in cornerPixelList {
            initialCornerAuroraValues.append(latitudeList[item]) // was latitude list
            cornerAuroraValues.append(initialList[item])
            
            
        }
        
        
        if latitudeList.count > 4 {
            
            var bottomLeftAuroraValue: Double = 0
            var topLeftAuroraValue: Double = 0
            var bottomRightAuroraValue: Double = 0
            var topRightAuroraValue: Double = 0
            
            // Bottom Left Corner
            
//            print(initialCornerAuroraValues)
//            print(cornerAuroraValues)
            
            //print(allChangedLatitudeAuroraValues)
            //print(allChangedLongitudeAuroraValues)
            
            // i guess im on right track, figure out later
            
//            print(updatedLatitudeAuroraValues)
//            print(updatedLongitudeAuroraValues)
            
            
            // i think i can figure which ones i need to pick for my testing, first 2 and last 2 for each, see them
             
            
            bottomLeftAuroraValue = (updatedLatitudeAuroraValues[0].aurora + updatedLongitudeAuroraValues[0].aurora) / 2
            
            bottomRightAuroraValue = (updatedLatitudeAuroraValues[updatedLatitudeAuroraValues.count - 2].aurora + updatedLongitudeAuroraValues[1].aurora) / 2
            
            topLeftAuroraValue = (updatedLatitudeAuroraValues[1].aurora + updatedLongitudeAuroraValues[updatedLongitudeAuroraValues.count - 2].aurora) / 2
            
            topRightAuroraValue = (updatedLatitudeAuroraValues[updatedLatitudeAuroraValues.count - 1].aurora + updatedLongitudeAuroraValues[updatedLongitudeAuroraValues.count - 1].aurora) / 2

            
            // each value can be calculated by combining 2 calculated values from x and y parallels and divide by 2
            
//            bottomLeftAuroraValue = 0.0
//            bottomLeftAuroraValue = initialCornerAuroraValues[1].aurora + initialCornerAuroraValues[2].aurora
//            bottomLeftAuroraValue = bottomLeftAuroraValue / 2
        
            
            // top Left Corner
            
//            topLeftAuroraValue = 0.0
//            topLeftAuroraValue = initialCornerAuroraValues[4].aurora + initialCornerAuroraValues[7].aurora
//            topLeftAuroraValue = topLeftAuroraValue / 2
            
            // bottom right corner
            
            
//            bottomRightAuroraValue = 0.0
//            bottomRightAuroraValue = initialCornerAuroraValues[8].aurora + initialCornerAuroraValues[11].aurora
//            bottomRightAuroraValue = bottomRightAuroraValue / 2
            
            // top right corner
            
            
//            topRightAuroraValue = 0.0
//            topRightAuroraValue = initialCornerAuroraValues[13].aurora + initialCornerAuroraValues[14].aurora
//            topRightAuroraValue = topRightAuroraValue / 2
            
            /*
            print(initialList)
            print(latitudeList)
            
             print("new values")
             print(bottomLeftAuroraValue)
             print(topLeftAuroraValue)
             print(bottomRightAuroraValue)
             print(topRightAuroraValue)
             
             print("values to replace")
             
             print(latitudeList[0].aurora)
             print(latitudeList[height - 1].aurora)
             print(latitudeList[latitudeList.count - height].aurora)
             print(latitudeList[latitudeList.count - 1].aurora)
            
             */
             
            latitudeList[0].aurora = bottomLeftAuroraValue
            latitudeList[height - 1].aurora = topLeftAuroraValue
            latitudeList[latitudeList.count - height].aurora = bottomRightAuroraValue // -1 wasnt there
            latitudeList[latitudeList.count - 1].aurora = topRightAuroraValue
            
            
//            print(latitudeList)
//            print(initialBackupList)
//            print()
            
            //            print(bottomLeftAuroraValue)
            //            print(topLeftAuroraValue)
            //            print(bottomRightAuroraValue)
            //            print(topRightAuroraValue)
            //            for item in initialCornerAuroraValues {
            //                print(item.aurora)
            //            }
            
            
//            print(latitudeList)
            
//            print()
            
        }
        
        
        
        
        // special case when there are only 4 corner values, and whole rectangle is inside whole coorindate bound.
        
        if latitudeList.count == 4 { // within 1 coordinate
            
            // unique condition, can be used overall for any 2 sided things.
            
            // even this might be redundant.
            
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
            
        }
        
        // R E B U I L D
        
        // i would need to pass ratios of aurora locations, and spreadCoordinate should account for this as well.
        /*
         
         I would essentially need to create a new method for each line of coordinates, to keep ratios together.
         Calculations would need to be done within the function and would be passing indexes with correct rations down the function
         There are also other possible problems like for example outOfReach coordinates with inf values
         
         instead of passing for each individual coordinate here, i can do it straight in a spreadCoordinate func
         
         */
        
        // Do i even need this?
        
        
        
        
        if maxLongitude >= 360 {
            var cycleIndex = 0
            for item in latitudeList {
                if item.longitude >= 360 {
                    let newItem = IndividualAuroraSpot(longitude: 359.0, latitude: item.latitude, aurora: item.aurora)
                    latitudeList[cycleIndex] = newItem
                }
                cycleIndex += 1
            }
        }
         
        

        indexWidth = spreadCoordinatesForRes(minValue: minLongitude,
                                             maxValue: maxLongitude,
                                             dimension: width,
                                             coordinateType: "Longitude",
                                             zoom: zoom
        )
        
        indexHeight = spreadCoordinatesForRes(minValue: bottomLatitude,
                                              maxValue: topLatitude,
                                              dimension: height,
                                              coordinateType: "Latitude",
                                              zoom: zoom)
        
        
        // indexHeight = indexHeight.reversed()
        // indexWidth = indexWidth.reversed()
        
        //        var newReversedIndexWidth: [Double] = []
        //        var newReversedIndexHeight: [Double] = []
        
        //        newReversedIndexWidth = indexWidth.reversed()
        //        newReversedIndexHeight = indexHeight.reversed()
        
        // indexValues start with lower and go up to a higher num
        
        //        print(inputTileCoordinateList)
        //        print(latitudeList)
        //        print()
        
        //  FIXED ONE PROBLEM, UP TO A NEXT
        
//        print(indexHeight.reversed())
//        print(latitudeList[0...height-1])
        
//        print(initialList)
//        print(latitudeList)
//        print(rotateList(inputList: latitudeList, height: height, width: width))
//        print()
        
        return (latitudeList, width, height, indexWidth, indexHeight)
    }
    
    func calculateLongitude(inputLongitude: Double, coordinateZoom: Int) -> Double {
        
        let mapSide = Double(coordinateZoom)
        
        var resolution = Double(pow(2, mapSide))
        
        resolution = 255 * resolution // try to change to 255 // was 256
        
        let outputLongitude = inputLongitude * (resolution / 360)
        
        return outputLongitude
    }
    
    // rotate list
    
    func rotateList(inputList: [IndividualAuroraSpot], height: Int, width: Int) -> [IndividualAuroraSpot] {
        // Calculate to which direction i will rotate the list, account for all sizes, min is 4
        // output list should start with topLeft value, min longitude, max latitude.
        // Each line should contain same latitude, different longitude values
        
        // works now, rotate different direction lmao
        
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
                // itemIndex = itemIndex + Int(height)
                itemIndex = itemIndex + height
            }
            
            itemIndex = (height - 1) - column
            //itemIndex = 1 + column
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
        
        let newResolution = resolution * 255 // thats a weird solution
        
        resolution = 256 * resolution // swap top 255? // was 255, changed to 256
        
        let latRad = inputCordinate * Double.pi / 180
        let mercN = log(tan((Double.pi / 4) + (latRad / 2)))
        
        let outputLatitude = (resolution / 2) - (newResolution * mercN / (2 * Double.pi))
        
        return outputLatitude
    }
    
    // Complex function that returns tile png.
    
    func createRectanglePNG(inputList: [IndividualAuroraSpot],
                            width: Int,
                            height: Int,
                            indexWidth: [Double],
                            indexHeight: [Double],
                            maxAurora: Double) -> CGImage {
        
        // breaking down from other function to simplify it
        
        var testList: [IndividualAuroraSpot] = []
        var newIndexHeight: [Double] = []
        newIndexHeight = indexHeight.reversed()
        var auroraIndex = 0

        
        let rotatedList = rotateList(inputList: inputList, height: height, width: width)
        
        /*
         was
         
         for longitude in indexWidth {
             var originalFlip: [IndividualAuroraSpot] = []
             for latitude in newIndexHeight {
                 let newCorrdinate = IndividualAuroraSpot(longitude: Double(longitude),
                                                          latitude: Double(latitude),
                                                          aurora: rotatedList[auroraIndex].aurora)
 //                originalValueList.append(inputList[auroraIndex])
                 auroraIndex = auroraIndex + 1
                 originalFlip.append(newCorrdinate)
                 
             }

             testList.append(contentsOf: originalFlip)
             
             originalFlip = []
         }
         
         
         */

        for latitude in newIndexHeight {
            var originalFlip: [IndividualAuroraSpot] = []
            for longitude in indexWidth {
                let newCorrdinate = IndividualAuroraSpot(longitude: Double(longitude),
                                                         latitude: Double(latitude),
                                                         aurora: rotatedList[auroraIndex].aurora)
//                originalValueList.append(inputList[auroraIndex])
                auroraIndex = auroraIndex + 1
                originalFlip.append(newCorrdinate)
                
            }

            testList.append(contentsOf: originalFlip)
            
            originalFlip = []
        }

        // Index width and indexHeight might not be same anymore, since orientation is changed
        
        /*
         
         fun fact
         indexHeight and IndexWidth start from lower num to heigher num, so for my new list - accouunt for this
         
         height list should be flipped
         
         */
        
//        print(inputList)
//        print(rotatedList)
//        print(testList)
//        print()
        // create an aurora values list.
        
        let auroraQuickList = testList.map { $0.aurora }
        
//        var product: [AuroraCoordinateRectangle] = []
        
        var emptyList: [Double] = []
        
        // create an empty list that will return an empty picture.
        
        for _ in 0...((256 * 256) - 1) {
            emptyList.append(0.0)
        }
        
        var gradientPixelArray: [Double] = []
        
        // Testing gradient list function with a simple list
        // list will have 25 values
        /*
        let testHeightList = [0.0, 10.0, 128.0, 245.0, 255.0]
        let testWidthList = [255.0, 245.0, 128.0, 10.0, 0.0]
        let testWidth = 5
        let testHeight = 5
        let testValuesList = [IndividualAuroraSpot(longitude: 0.0, latitude: 0.0, aurora: 0.81),
                              IndividualAuroraSpot(longitude: 10.0, latitude: 0.0, aurora: 0.875),
                              IndividualAuroraSpot(longitude: 128.0, latitude: 0.0, aurora: 0.1),
                              IndividualAuroraSpot(longitude: 245.0, latitude: 0.0, aurora: 0.375),
                              IndividualAuroraSpot(longitude: 255.0, latitude: 0.0, aurora: 0.81),
                              
                              IndividualAuroraSpot(longitude: 0.0, latitude: 10.0, aurora: 0.75),
                              IndividualAuroraSpot(longitude: 10.0, latitude: 10.0, aurora: 1),
                              IndividualAuroraSpot(longitude: 128.0, latitude: 10.0, aurora: 0.1),
                              IndividualAuroraSpot(longitude: 245.0, latitude: 10.0, aurora: 0.5),
                              IndividualAuroraSpot(longitude: 255.0, latitude: 10.0, aurora: 0.75),
                              
                              IndividualAuroraSpot(longitude: 0.0, latitude: 128.0, aurora: 0.1),
                              IndividualAuroraSpot(longitude: 10.0, latitude: 128.0, aurora: 0.1),
                              IndividualAuroraSpot(longitude: 128.0, latitude: 128.0, aurora: 0.1),
                              IndividualAuroraSpot(longitude: 245.0, latitude: 128.0, aurora: 0.1),
                              IndividualAuroraSpot(longitude: 255.0, latitude: 128.0, aurora: 0.1),
                              
                              IndividualAuroraSpot(longitude: 0.0, latitude: 245.0, aurora: 0.5),
                              IndividualAuroraSpot(longitude: 10.0, latitude: 245.0, aurora: 0.75),
                              IndividualAuroraSpot(longitude: 128.0, latitude: 245.0, aurora: 0.1),
                              IndividualAuroraSpot(longitude: 245.0, latitude: 245.0, aurora: 0.25),
                              IndividualAuroraSpot(longitude: 255.0, latitude: 245.0, aurora: 0.5),
                              
                              IndividualAuroraSpot(longitude: 0.0, latitude: 255.0, aurora: 0.81),
                              IndividualAuroraSpot(longitude: 10.0, latitude: 255.0, aurora: 0.875),
                              IndividualAuroraSpot(longitude: 128.0, latitude: 255.0, aurora: 0.1),
                              IndividualAuroraSpot(longitude: 245.0, latitude: 255.0, aurora: 0.375),
                              IndividualAuroraSpot(longitude: 255.0, latitude: 255.0, aurora: 0.81),
        ]
        */
        
        /*
         
         let testValuesList = [IndividualAuroraSpot(longitude: 0.0, latitude: 0.0, aurora: 0.81),
                               IndividualAuroraSpot(longitude: 10.0, latitude: 0.0, aurora: 0.875),
                               IndividualAuroraSpot(longitude: 128.0, latitude: 0.0, aurora: 0.1),
                               IndividualAuroraSpot(longitude: 245.0, latitude: 0.0, aurora: 0.375),
                               IndividualAuroraSpot(longitude: 255.0, latitude: 0.0, aurora: 0.81),
                               
                               IndividualAuroraSpot(longitude: 0.0, latitude: 10.0, aurora: 0.75),
                               IndividualAuroraSpot(longitude: 10.0, latitude: 10.0, aurora: 1),
                               IndividualAuroraSpot(longitude: 128.0, latitude: 10.0, aurora: 0.1),
                               IndividualAuroraSpot(longitude: 245.0, latitude: 10.0, aurora: 0.5),
                               IndividualAuroraSpot(longitude: 255.0, latitude: 10.0, aurora: 0.75),
                               
                               IndividualAuroraSpot(longitude: 0.0, latitude: 128.0, aurora: 0.1),
                               IndividualAuroraSpot(longitude: 10.0, latitude: 128.0, aurora: 0.1),
                               IndividualAuroraSpot(longitude: 128.0, latitude: 128.0, aurora: 0.1),
                               IndividualAuroraSpot(longitude: 245.0, latitude: 128.0, aurora: 0.1),
                               IndividualAuroraSpot(longitude: 255.0, latitude: 128.0, aurora: 0.1),
                               
                               IndividualAuroraSpot(longitude: 0.0, latitude: 245.0, aurora: 0.5),
                               IndividualAuroraSpot(longitude: 10.0, latitude: 245.0, aurora: 0.75),
                               IndividualAuroraSpot(longitude: 128.0, latitude: 245.0, aurora: 0.1),
                               IndividualAuroraSpot(longitude: 245.0, latitude: 245.0, aurora: 0.25),
                               IndividualAuroraSpot(longitude: 255.0, latitude: 245.0, aurora: 0.5),
                               
                               IndividualAuroraSpot(longitude: 0.0, latitude: 255.0, aurora: 0.81),
                               IndividualAuroraSpot(longitude: 10.0, latitude: 255.0, aurora: 0.875),
                               IndividualAuroraSpot(longitude: 128.0, latitude: 255.0, aurora: 0.1),
                               IndividualAuroraSpot(longitude: 245.0, latitude: 255.0, aurora: 0.375),
                               IndividualAuroraSpot(longitude: 255.0, latitude: 255.0, aurora: 0.81),
         ]
         
         */
        
        
        
        for aurora in auroraQuickList {
            if aurora != 0 {
                /*
                // create for each line a new color for test?
                print("inputList")
                print(inputList)
                print("rotated list")
                print(rotatedList)
                print("rotated list with new values")
                print(testList)
                print()
                 
                 */
                /*
                 previous
                 
                let experiment = createGradientList(inputList: testList,
                                                    height: height,
                                                    width: width,
                                                    heightIndex: newIndexHeight,
                                                    widthIndex: indexWidth)
                 */
                
                let experiment = createGradientList(inputList: testList,
                                                    height: height,
                                                    width: width,
                                                    heightIndex: newIndexHeight,
                                                    widthIndex: indexWidth)
                
                /*
                let experiment = createGradientList(inputList: testValuesList,
                                                    height: testHeight,
                                                    width: testWidth,
                                                    heightIndex: testHeightList,
                                                    widthIndex: testWidthList)
                */
                gradientPixelArray = experiment
                break
                
            } else {
                gradientPixelArray = emptyList
            }
        }
        
        // Create an empty UInt32 list, that will be used to fill with actual color value.
        
        var pixelGrid: [UInt32] = []
        
        var auroraAlpha: Double = 0
        
        if maxAurora != 0 {
            auroraAlpha = 1.0 / maxAurora // this is amount of increments from 0 to 1 based on aurora strength
        }
        
        // Create color scheme for overlay image
        
        let color = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.0)
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        // For each gradient value add either a value or an empty pixel

        /*
         
         original color
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32((currentAuroraAlpha) * 255.0) << 24 +
             UInt32((blue) * 255.0) << 16 +
             UInt32((1) * 255.0) << 8 +
             UInt32(alpha * 255.0)
             
             pixelGrid.append(newColor)
             
         }
         
         */
        
        var emptyColor: UInt32 = 0
        
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            emptyColor += UInt32(0 * 255.0) << 24 + // alpha // was 0 // put 0 for empty spots not filled with anything
            UInt32(green * 255.0) << 16 +
            UInt32(blue * 255.0) << 8 +
            UInt32(alpha * 255.0)
        }
        
        if gradientPixelArray.count == 0 {
            print(inputList)
            print(indexWidth)
            print(newIndexHeight)
            print()
        }
        
        var calcIndex = 0
        
        for item in gradientPixelArray {
            if item < 0.0 || item.isNaN {
                print(item)
                
                print(gradientPixelArray[calcIndex...calcIndex+100])
                print()
                }
            calcIndex = calcIndex + 1
        }

        for item in gradientPixelArray {
            if item != 0 {
                var newColor: UInt32 = 0
                let currentAuroraAlpha = Double(item) * auroraAlpha
                
                if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    newColor += UInt32((currentAuroraAlpha) * 255.0) << 24 +
                    UInt32((blue) * 255.0) << 16 +
                    UInt32((1) * 255.0) << 8 +
                    UInt32(alpha * 255.0)
                    
                    pixelGrid.append(newColor)
                    
                }
                
            } else {
                pixelGrid.append(emptyColor)
            }
            
        }
        
        func rotateList(inputList: [IndividualAuroraSpot], height: Int, width: Int) -> [IndividualAuroraSpot] {
            // Calculate to which direction i will rotate the list, account for all sizes, min is 4
            // output list should start with topLeft value, min longitude, max latitude.
            // Each line should contain same latitude, different longitude values
            
            // works now, rotate different direction lmao
            
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
                    // itemIndex = itemIndex + Int(height)
                    itemIndex = itemIndex + height
                }
                
                itemIndex = (height - 1) - column
                //itemIndex = 1 + column
                outputList.append(contentsOf: rowList)
                rowList = []
            }
            
            
            return outputList
        }

        // function to rotate an image 90degrees, Will be removed later, since creates extra processing.
        // rotates only squares
        
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
        
        // temp function to create images.

        // find orientation for a list picture, from it structure my data in that order for me to understand it easier.
        
        // Oreientation for a bitmap picture is topLeft -> topRight, bottomLeft -> bottomRight.
        // Current list oreitntation is topLeft -> bottomLeft
        
        
        func createSimpleImage(inputList: [UInt32]) -> CGImage {
            
            var gridList = inputList
            
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

        
        if pixelGrid.count != 65536 {
            print(pixelGrid.count)
            print()
        }
        
        let finalImage = createSimpleImage(inputList: pixelGrid) // no rotation is needed now?
        // lmao what have i done
//        let finalImage = createSimpleImage(inputList: funPixelList)

        
        return finalImage
    }
    
    // function to process only whole nums
    // Not implemented now.
    
    func wholeNumberProcessing(inputAuroraList: [IndividualAuroraSpot],
                               minLongitude: Double,
                               maxLongitude: Double,
                               bottomLatitude: Double,
                               topLatitude: Double) -> [IndividualAuroraSpot] {
        
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
    
    func spreadCoordinatesForRes(minValue: Double,
                                 maxValue: Double,
                                 dimension: Int,
                                 coordinateType: String,
                                 zoom: Int) -> [Double] {
        
        if dimension == 0 {
            print(maxValue)
            print(minValue)
        }
        
        // Later i would need to rework this whole function.
        
        var experimentalListRounded: [Double] = []

        
        /*
         
         It's reasonable to assume that i should rewrite this whle function.
         
         i would need to create an elegant and simple tactics to translate coordinate borders to correct coordinate
            on 256 x 256 tile
         
         First would be to Use function with mercator projections for both longitude and latitude
         
         first coordinate will be 0, last coordinate might be 255
         
         drop old function and move on to a new, precise one.
         
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
 
        
        //        print(wholeCoordinateList)
        //        print()
  
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
            
            
            if experimentalListRounded.count > 3 {
                if experimentalListRounded[experimentalListRounded.count - 2] >= 255.0 {
                    
                    experimentalListRounded[experimentalListRounded.count - 2] = 254.0
                    
//                    print(experimentalListRounded)
//                    print(latitudeMercatorList)
//                    print()
                    
                    // I have an idea for a solution?
                    /*
                    if experimentalListRounded.count == latitudeMercatorList.count {
                        // extra value got there?
                        experimentalListRounded.remove(at: experimentalListRounded.count - 1)
                        experimentalListRounded[experimentalListRounded.count - 1] == 255.0
                    }
                     */
                    // experimentalListRounded[experimentalListRounded.count - 2] = 254.0
                }
            }
             
        
//            print(latitudeMercatorList)
//            print(experimentalList)
//            print(experimentalListRounded)
            
            
            
            /*
            print(differenceList) // list with proportions that can be used for pixels
            print(possiblyPixelList)
            print(roundedValuesSimple)
            print(possiblyRoundedPixelList)
            let count = differenceList.reduce(0, {x, y in x + y})
             */
            // print(count)
            /*
            if sumOfStuff.rounded() != 255 {
                print(experimentalListRounded)
                print(latitudeMercatorList)
                print()
            }
            */
//            print(sumOfStuff)
//            print()
        
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
        // Will be simplified when I would have a better understanding.
        
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
            
            // maybe have an if/else here?
            
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
            
//            itemsNum = itemsToFill
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
        
        outputList.append(256.0) // ill keep it as an outOfBound index for now. as later i might be able to purely avoid it.
        
        return outputList
    }
    
    // New function, replacing parseMerc and createGRadient
    // new function will save on processing, and should be more omptimal. It would accept updated coordinate grid,
    // and create list for a picture, or a picture in future
    
    func createGradientList(inputList: [IndividualAuroraSpot],
                            height: Int,
                            width: Int,
                            heightIndex: [Double],
                            widthIndex: [Double]) -> [Double] {
        
        /*
         
         Current function plan:
         
         1. Accept list with coordinates spread to 0...255 range
         2. Rotate list 90 Degress while its relatively small // passing already rotated list
         3. For each Height value create a list with width values, changing width value to incremental difference
         4. (do later?) Create a list of 0 size 256 items. This would be an initial Line list
         5. For each Height value create a list with width values, each longitude index == position on line list, fill aurora
         6. for each list, for each width replace 0 with appropriate values calculated based of difference
         7. Append all lists into one.
         
         */
        /*
        if inputList.count < 25 {
            print(inputList)
        }
        */
        // var outputList: [Double] = []
        
        // Rotate list? // will do later, since other part is as important
        // initialize a width column list
        
        var widthList: [Double] = []
        var heightList: [Double] = []
        
        widthList = widthIndex // .reversed() // was not reversed
        heightList = heightIndex // .reversed() // reversing both doesn't do ahything
        
        var auroraColumnList: [Double] = []
        var auroraRowList: [Double] = []
        
        // these two might be wrong
        
        for item in inputList[0...(width - 1)] {
            auroraRowList.append(item.aurora)
        }
        
        /*
         
         for item in 0...(width - 1) {
             auroraRowList.append(inputList[item * height].aurora)
         }
         
         */
        auroraColumnList.append(inputList[0].aurora)
        
        for item in 1...height - 1 {
            auroraColumnList.append(inputList[item * width].aurora)
        }
        
        //var columnList: [Double] = []
        var rowList: [Double] = []
        var emptyZeroList: [Double] = []
        
        for _ in 0...255 {
            //columnList.append(0.0)
            rowList.append(0.0)
            emptyZeroList.append(0.0)
        }
        
        var cycleIndex = 0
        
        //var reversedColumnList = columnList
        //reversedColumnList = reversedColumnList.reversed()
        
        //for item in heightList.reversed() {
        //    columnList[Int(item)] = auroraColumnList[cycleIndex]
        //   cycleIndex += 1 // replace with this
        //}
        
        cycleIndex = 0
        
        for item in widthList {
            rowList[Int(item)] = auroraRowList[cycleIndex]
            cycleIndex += 1
        }

        /*
        
        print(height)
        print(width)
        print(inputList[0...width-1])
        print(rowList) // should be only first 256 values with zeros
        print(columnList) // should be reversed?
        print()
        
         */
        /*
         
         Make it simpler now delete older calculations and replace with a newer simpler way
         
         write a function to process each line with 0 and non 0 values based on list
         
         for now create a loop that processes all items in list within a 256 range
         
         */
        
        // so far so good.
        
        // create a difference between each value, to calculate index differences
        // keep values inbetween indexes only
        
        func differenceBetweenCoordinateValues(inputFuncList: [Double]) -> [Int] {
            var processedLst = inputFuncList
            
            var previousDistanceDifferenceValue = 255.0
            var firstZero = false
            
            if processedLst[0] != 255.0 {
                processedLst = processedLst.reversed()
                firstZero = true
                
            }
            
            var distanceDifferenceList: [Int] = []
            
            for item in processedLst {
                var differenceValue = 0
                
                differenceValue = Int(abs(item - previousDistanceDifferenceValue))
                previousDistanceDifferenceValue = item - 1
                
                
                distanceDifferenceList.append(differenceValue)
            }
            
            if distanceDifferenceList[0] == 0 {
                distanceDifferenceList.remove(at: 0)
            }
            
            if firstZero {
                distanceDifferenceList = distanceDifferenceList.reversed()
            }
            /*
            var localCycleIndex = 0
            
            for item in distanceDifferenceList {
                if item == 0 {
//                    print(inputFuncList)
                    //distanceDifferenceList.remove(at: localCycleIndex)
                    //print(distanceDifferenceList)
                    
//                    print()
                    
                }
                localCycleIndex += 1
            }
             */
            
            return distanceDifferenceList
        
            
        }
        
        // calculating empty spacess between values. can be useful later.
    
        // var zeroCount = 0
        
        /*
        for item in columnList { // was not reversed
            if item == 0.0 {
                zeroCount = zeroCount + 1
            } else {
                if zeroCount == 0 {
                    
                } else {
                    zeroCountList.append(zeroCount)
                    zeroCount = 0
                }
            }
        }
        
        if zeroCount != 0 {
            zeroCountList.append(zeroCount)
        }
        */
        
        var secondAuroraColumnList: [Double] = []
        
        for item in inputList[height...((height * 2) - 1)] {
            secondAuroraColumnList.append(item.aurora)
        }
        
        // list with original aurora values, each list inside a list is a column
        
        var listWithOriginaHeighValues: [[Double]] = []
        var tempRowList: [Double] = []
        
        // create a loop that will loop WidthTimes to append Height columns with values
        // also create a list with coordinate values
        // maybe as well create a fill list?
        
        
        /*
         was
         
         for row in 0...(width - 1) {
             for item in inputList[(height * row)...((height * (row + 1)) - 1)] {
                 tempRowList.append(item.aurora)
                 
             }
             listWithOriginaHeighValues.append(tempRowList) // was NOT reversed
             
             tempRowList = []
         }
         
         
         
         */
        
        for row in 0...(height - 1) {
            for item in inputList[(width * row)...((width * (row + 1)) - 1)] {
                tempRowList.append(item.aurora)
                
            }
            listWithOriginaHeighValues.append(tempRowList) // was NOT reversed
            
            tempRowList = []
        }
        
        // now when a list with columns exists, for each list i can create a list of
        
        // work out correct logic, im etting confused again.
        
        func fillCoordinateWithZeros(inputCoordinateList: [Double]) -> [Double] {
            var emptyList: [Double] = []
            
            for _ in 0...255 {
                emptyList.append(0.0)
            }
            
            var cycleFuncIndex = 0
            
            for item in inputCoordinateList {
                emptyList[Int(item)] = item
                cycleFuncIndex = cycleFuncIndex + 1
            }

            return emptyList
        }

  
        
        let zeroRowCount = differenceBetweenCoordinateValues(inputFuncList: widthList) // use coordinate instead
        let zeroColumnCount = differenceBetweenCoordinateValues(inputFuncList: heightList) // use coordinate instead
        
        // zeroColumnCount = zeroColumnCount.reversed() // what?

        // let indexOfItemsToFill = 0
        //var listCountCycle = 0
        // var wholeValue = true
        
        
        // create a func to calculate zeros and just append with amount to each list?
        // no matter what, its all complicated. i start to hate it lmao
        // cycle through column lists, for each step take away 1
        // just get an index of zeros
        
        /*
         
         Whole cycle is still a subject to careful analysis to make sure calculations are correct
         
         thy are not lmao
         
         */

        
        
        var tempLineList: [[Double]] = []
        
        // write temp function to return only dots with values.
        
        // print(inputList)
        
        /*
        print(listWithOriginaHeighValues) // should be height amount of lists, each having width amount of values
        print()
         
         */
        /*
         was
         for list in listWithOriginaHeighValues {
             
             var colIndexNum = 0
             var tempColList: [Double] = []
             
             for item in 1...list.count-1  {
                 
                 tempColList.append(list[item - 1])
                 
                 if zeroColumnCount[colIndexNum] > 0 {
                     var reversedList = zeroColumnCount
 //                    reversedList = reversedList.reversed()
                     for _ in 1...reversedList[colIndexNum] {
                         tempColList.append(list[item - 1])
                     }
                 }
                 colIndexNum += 1
                 
             }
             
             tempColList.append(list[colIndexNum])
             
             tempLineList.append(tempColList.reversed()) // was not reversed
             
             tempColList = []
             colIndexNum = 0
         }
         
         
         */
        
        /*
         
         to create gradient, we have at least 3 coordinate values, and 2 aurora values
         each whole value will be in the end and in the beginning
         append first item, then cycle through a list and append other items
         
         
         */
        
        var newGradientColumnList: [[Double]] = []
        
        // append first list to a new list
        
        newGradientColumnList.append(listWithOriginaHeighValues[0])
        
        var nextRowListIndex = 1
        // i can use zeroCount?
        
        // print(zeroCountList)
        
        
        
        // print all values so i see what am i working with
        /*
        print(zeroColumnCount) // correct orientation
        print(zeroRowCount) // correct orientation
        print(inputList) // top -> left -> right -> bottom, correct
        // print(columnList) // not correct, try columnList.reversed
        print(rowList) // correct
        print(listWithOriginaHeighValues)
        print()
        */
        
        
        for item in zeroColumnCount { // zeroCountList
            // for each zero value i will create gradient lists, and append them min value is 1, max value is 255?
            // calculate how many times it will cycle
            // current and previous lists with values
            
            // previous - current
            // 6 - 5 - 1
            // 5 - 6 = -1, (-1 * steps, from 0 to 1) + 6
            
            if item != 0 {
                let currentList = listWithOriginaHeighValues[nextRowListIndex]
                let previousList = listWithOriginaHeighValues[nextRowListIndex - 1]
                // list with incremental difference between current and previous list
                var differenceBetweenCurrentAndPreviousValues: [Double] = []
                
                var incrementCycleListIndex = 0
                
                for value in currentList {
                    let newIncrementalValue = previousList[incrementCycleListIndex] - value
                    incrementCycleListIndex += 1
                    
                    if newIncrementalValue.isNaN || newIncrementalValue.isInfinite {
                        print(value)
                        print(previousList[incrementCycleListIndex])
                        print()
                        
                    }
                    
                    differenceBetweenCurrentAndPreviousValues.append(newIncrementalValue)
                }
                
    //            print(previousList)
    //            print(currentList)
    //            print(differenceBetweenCurrentAndPreviousValues)
    //            print()
                
                var listOfAppendingValues: [[Double]] = []
                
                for increment in 0...item {
                    // new empty list that we will append values to
                    var newListItemIndex = 0
                    var appendingNewValuesList: [Double] = []
                    // here goes main cycle
                    // for each value in current list, add increments, from 0 to last item
                    
                   //  var incrementingValue = fullIncrementValue - Double(increment / item)
                    let incrementingValue = Double(increment) / Double(item)
                    
                    if incrementingValue.isNaN || incrementingValue.isInfinite {
                        print(Double(increment))
                        print(Double(item))
                        print()
                    }
                    
                    for itemFromCurrentList in currentList {
                        let newAppendingValue = itemFromCurrentList + (differenceBetweenCurrentAndPreviousValues[newListItemIndex] * Double(incrementingValue))
                        
                        if newAppendingValue.isNaN || newAppendingValue.isInfinite {
                            print(itemFromCurrentList)
                            print(differenceBetweenCurrentAndPreviousValues[newListItemIndex])
                            print(Double(incrementingValue))
                        }
                        
                        appendingNewValuesList.append(newAppendingValue)
                        newListItemIndex += 1
                    }
                    
                    listOfAppendingValues.append(appendingNewValuesList)
    //                print(appendingNewValuesList)
    //                print()
                }
                
                newGradientColumnList.append(contentsOf: listOfAppendingValues.reversed())
                
            } else {
                // append next thing ??
                
                newGradientColumnList.append(listWithOriginaHeighValues[nextRowListIndex])
//                print(newGradientColumnList.count)
//                print()
            }
            
//            print(listOfAppendingValues.count)
//            print(newGradientColumnList)
//            print()
            
            
            nextRowListIndex += 1
        }
        
        if newGradientColumnList.count > 256 {
            //ONLY TEMP
            newGradientColumnList.remove(at: newGradientColumnList.count - 1)
        }
        
        
//        print(newGradientColumnList.count)
//        print()
        
        
        
        // cycle through each list with a create gradient function and return a main list
        
        var finalOutputList: [Double] = []
        
        for list in newGradientColumnList {
            let newGradientList = fillLineWithGradient(inputLine: list, lengthZeros: zeroRowCount) //zeroRowCount
            finalOutputList.append(contentsOf: newGradientList)
        }
        
        if finalOutputList.count != 65536 {
            //print(finalOutputList.count)
            //print(newGradientColumnList)
            
            let deleteIndex = 65536
            
            let upperRange = finalOutputList.count
            
            
            for _ in 65536...upperRange - 1 {
                finalOutputList.remove(at: deleteIndex)
            }
            
            print(heightIndex)
            print(widthIndex)
            print(finalOutputList.count)
            print()
        }
        
        //print(newGradientColumnList)
        //print()
        
        
        for list in listWithOriginaHeighValues {
            
            var colIndexNum = 0
            var tempColList: [Double] = []
            
            for item in 1...list.count-1  {
                
                tempColList.append(list[item - 1])
                
                if zeroRowCount[colIndexNum] > 0 {
                    let reversedList = zeroRowCount
//                    reversedList = reversedList.reversed()
                    for _ in 1...reversedList[colIndexNum] {
                        tempColList.append(list[item - 1])
                    }
                }
                colIndexNum += 1
                
            }
            
            tempColList.append(list[colIndexNum])
            
            tempLineList.append(tempColList) // was not reversed // was .reversed(), i changed it
            
            tempColList = []
            colIndexNum = 0
        }
        
//        print(tempLineList)
//        print()
        
        var outputTenpList: [Double] = []
        
        var rowListIndex = 0
        
        let lstValue = tempLineList[tempLineList.count-1]
        
        tempLineList.remove(at: tempLineList.count-1)
        
        for list in tempLineList {
            
            // for each full column, create a new filled one
            
            var tempFullList: [Double] = []
            
            for _ in 0...zeroColumnCount[rowListIndex] {
                tempFullList.append(contentsOf: list)
            }
            rowListIndex += 1
            
            outputTenpList.append(contentsOf: tempFullList)
          //   tempFullList = []
        }
        
        outputTenpList.append(contentsOf: lstValue)
        
        
        // current method was used to create a gradient tile. I still have to fix input data to make sure it looks good.
        // Not implemented.
        
        
        // write a new function for gradient
        
        
        // cycle through
        
        // write this into a file, so i can read each item individyally.
        
        let listWithoutGradientWidth: [[Double]] = []
        
        // for now do not use
        
        // MAIN FUNCTION
        
        // RESTRUCTURE
        
        /*
         
         Main goal of this function would be to implement line per line function of creating gradient between all values
         
         Each line would be checked for existing values and fill them up
         
         it would be smart to create a list of 256 items with lists thaty only needs to be filled, and then process them
         
         it might take a bit more time, but for now it would be cleaner.
         
         for now, separate into two functions for clean implementation
         
         */
        
        
        // swapped row for column count
        
        /*
        
        for list in listWithOriginaHeighValues {
            
            if !wholeValue {
                if zeroColumnCount[listCountCycle - 1] < 0 {
                    wholeValue = true
                }
            }
            
            if wholeValue {
                
                let gradientProduct = fillLineWithGradient(inputLine: list, lengthZeros: zeroRowCount)
                possibleFinalList.append(contentsOf: gradientProduct) // was reversed
                listWithoutGradientWidth.append(list)
                
                var calcIndex = 0
                
                for item in gradientProduct {
                    if item < 0.0 || item.isNaN {
                        print(item)
                        
                        print(gradientProduct)
                        print()
                        }
                    calcIndex = calcIndex + 1
                }
                
//                print("reversed column with full items \(list.reversed())")
//                print("number of zero elements with full items \(zeroColumnCount)")
//                print("gradient product, 256 items that will fill a column \(gradientProduct)")
//                print()
                
                wholeValue = false
                
                // apends only 1 value if next is 0
                
            } else {
                
                // if fillItems is zero, skip whole thing i guess
                
                
                let fillItems = zeroColumnCount[listCountCycle - 1] // was - 1
                
                // if fillItems is 0, no items to fill
                
                // items to fill should not be less that 0, i need to restructure whole thing
                
                if fillItems > 0 {
                    // generates previous values, then
                    
                    //                var incrementValue = 0.0
                    var incrementIndex = 0
                    var newValueList: [Double] = []
                    let previousList = listWithOriginaHeighValues[listCountCycle - 1]
                    
                    
                    
                    for auroraValue in list {
                        let newItem = calculateIncrement(inputFirstNum: previousList[incrementIndex],
                                                         inputSecondNum: auroraValue,
                                                         distance: indexOfItemsToFill - 1)
                        
                        incrementIndex = incrementIndex + 1
                        newValueList.append(newItem)
                    }
                    
                    var incrementLoopIndex = 0
                    
                    let incrementValueBase = 1 / Double(fillItems)
                    
                    
                    for newItemList in 0...fillItems {
                        
                        let incrementDegree = Double(newItemList) * incrementValueBase
                        // new value list is just a list with increments.
                        
                        var updatedAppendingList: [Double] = []
                        
                        for increment in newValueList {
                            let newValue = previousList[incrementLoopIndex] + (increment * incrementDegree)
                            
                            incrementLoopIndex = incrementLoopIndex + 1
                            updatedAppendingList.append(newValue)
                        }
                        
                        incrementLoopIndex = 0

                        
                        
                        listWithoutGradientWidth.append(updatedAppendingList)
                        let gradientProduct = fillLineWithGradient(inputLine: updatedAppendingList, lengthZeros: zeroRowCount)
                        possibleFinalList.append(contentsOf: gradientProduct) // was reversed
                        
                        var calcIndex = 0
                        
                        for item in gradientProduct {
                            if item < 0.0 || item.isNaN {
                                print(item)
                                
                                print(gradientProduct)
                                print()
                                }
                            calcIndex = calcIndex + 1
                        }
                        
    //                    print(gradientProduct)
    //                    print()
 
                    }
                }
                
                listWithoutGradientWidth.append(list)
                let gradientProduct = fillLineWithGradient(inputLine: list, lengthZeros: zeroRowCount)
                
                var calcIndex = 0
                
                for item in gradientProduct {
                    if item < 0.0 || item.isNaN {
                        print(item)
                        
                        print(gradientProduct)
                        print()
                        }
                    calcIndex = calcIndex + 1
                }
                
//                print(gradientProduct)
//                print()
//                possibleFinalList.append(contentsOf: gradientProduct) // waas rever

                
            }
            
            listCountCycle = listCountCycle + 1
            
            // all appending values were reversed

        }
        
        // function that fills line with gradient
        
        */
        func fillLineWithGradient(inputLine: [Double], lengthZeros: [Int] ) -> [Double] {
            // cycle through each item, if it's non zero, append
            // if it is zero, create /empty spots/ times values list and append
            
            //                    let incrementDifference = calculateIncrement(inputFirstNum: previousValue,
            //                                                                 inputSecondNum: item,
            //                                                                 distance: distance)
            
            // var zeroList = lengthZeros
            // zeroList = zeroList.reversed() was reversed, now its normal
            
            var outputList: [Double] = []
            
            var wholeActualNum = inputLine[0]
            
            var itemAddedCount = 0
            
            
            //            print(inputLine)
            //            print(lengthZeros) // should be reversed, or other way? can be done later tho
            //            print()
            
            var wholeValue = true
            
            // cycle through each item, check if it's whole. Use previous function as an example
            
            for item in inputLine {
                
                //                if !wholeValue {
                //                    if lengthZeros[itemAddedCount - 1] < 0 {
                //                        wholeValue = true
                //                    }
                //                }
                
                if wholeValue {
                    
                    outputList.append(item)
                    wholeActualNum = item
                    
                } else {
                    // create a loop with incremented values and append
                    
                    let lineFillItems = lengthZeros[itemAddedCount - 1]
                    
                    var newLineList: [Double] = []
                    
                    if lineFillItems <= 0 {
                        
                        outputList.append(item)
                        wholeActualNum = item
                    } else {
                        
                        let previousValue = wholeActualNum
                        
                        let distance = lengthZeros[itemAddedCount - 1]
                        
                        let incrementVal = (item - previousValue) / Double(distance + 1)
                        
                        //print(incrementVal)
                        // print()
                        
                        for number in 0...lineFillItems - 1 {
                            
                            let newValue = previousValue + (Double(number + 1) * incrementVal)
                            
                            newLineList.append(newValue)
                            
                        }
                        
                        //                        print(newLineList)
                        //
                        outputList.append(contentsOf: newLineList)
                        
                        //                        print(newLineList.count)
                        //                        print(distance)
                        
                        outputList.append(item)
                        wholeActualNum = item
                    }
                    
                }
                
                itemAddedCount = itemAddedCount + 1
                wholeValue = false
                
            }
            
            for item in outputList {
                if item.isNaN || item.isInfinite {
                    print(inputLine)
                    print(lengthZeros)
                    
                    print(outputList)
                    print()
                }
            }
            
            
            //            outputList.append(inputLine[inputLine.count - 1])

            /*
            if outputList.count != 256 {
                print(outputList)
                print(outputList.count)
                print()
            }
            */
//            print(lengthZeros)
//            print(inputLine)
//            print(outputList)
//            print()
            
            return outputList // .reversed()
        }
        
        
        
        do {
            
            let data = try JSONEncoder().encode(listWithoutGradientWidth) // ???
            
            let fileURL = try! FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            .appendingPathComponent("outputList.json")
            
            try data.write(to: fileURL)

        } catch {
            print(error.localizedDescription)
        }

        
//        print(inputList)
//        print(listWithOriginaHeighValues)
       // print()
    
        
        // copy a coordinateFill list with new values
        
        func fillCoordinateValuesWithAurora(inputCoordinateList: [Double],
                                            inputValuesList: [Double],
                                            inputFillList: [Double]) -> [Double] {
            
            var outputList = inputFillList
            
            var cycleIndex = 0
            
            for coordinate in inputCoordinateList {
                outputList[Int(coordinate)] = inputValuesList[cycleIndex]
                cycleIndex = cycleIndex + 1
            }
            
            return outputList
            
        }
        

        // calculating increment for addition
        
        func calculateIncrement(inputFirstNum: Double, inputSecondNum: Double, distance: Int) -> Double {
            
            // Increment will be a difference between 2 aurora values / distance. Can be negative or positive
            // Increment will be added in cycle for each step to a previous number
            let increment = (inputFirstNum - inputSecondNum) / Double(distance)
            
            if increment.isNaN || increment.isInfinite {
                print(increment)
                print(inputFirstNum)
                print(inputSecondNum)
                print()
            }
            
            return increment
        }
        
        // calculatin empty spots for each column
        // each column list should have zeros inbetween!!!
        
        func calculateEmptySpotsBetweenValues(inputList: [Double]) -> [Int] {
            var zeroCountList: [Int] = []
            var zeroCount = 0
            
            for item in inputList {
                if item == 0.0 {
                    zeroCount = zeroCount + 1
                } else {
                    if zeroCount == 0 {
                        
                    } else {
                        zeroCountList.append(zeroCount)
                        zeroCount = 0
                    }
                }
            }
            
            if zeroCount != 0 {
                zeroCountList.append(zeroCount)
            }
            
            return zeroCountList
        }
        
        // fill values inbetween zeros for a list
        
        func fillCoordinateListWithZeros(inputCoordinateList: [Double], inputAuroraList: [Double]) -> [Double] {
            var indexesList: [Double] = []
            
            for _ in 0...255 {
                indexesList.append(0.0)
            }
            
            var cycleIndex = 0
            
            for item in inputCoordinateList {
                indexesList[Int(item)] = inputAuroraList[cycleIndex]
                cycleIndex = cycleIndex + 1
            }
            
            return indexesList
        }

       //  outputList = possibleFinalList
        
        return finalOutputList // outputTenpList // outputList
    }
    
}
    
