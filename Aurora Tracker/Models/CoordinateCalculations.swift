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
    // Not implemented.
    
    func filterMercatorValues(inputList: [IndividualAuroraSpot]) -> [IndividualAuroraSpot] {
        var filteredAuroraList: [IndividualAuroraSpot] = []
        
        for aurora in inputList {
            if aurora.latitude < 86 && aurora.latitude > -86 { // look up upper bounds for mercator projection
                filteredAuroraList.append(aurora)
            }
        }
        
        return filteredAuroraList
    }
    
    // For each tile returns corner values of requested tile.
    
    func tileToCoordinate(_ tileX: Int, _ tileY: Int, zoom: Int) -> ([Double]) {
        
        // corner values are necessary for calculating accurate tiles.

        var outputList: [Double] = [] // bottomLeftLat, bottomLeftLon, bottomRightLon, topLeftLat
        
        let res: Double = pow(2, Double(zoom))

        let bottomLeftLat = atan( sinh (.pi - (Double(tileY) / res) * 2 * Double.pi)) * (180.0 / .pi)
        let bottomLeftLon = (Double(tileX) / res) * 360.0
        let bottomRightLon = (Double(tileX + 1) / res) * 360.0
        let topLeftLat = atan( sinh (.pi - (Double(tileY + 1) / res) * 2 * Double.pi)) * (180.0 / .pi)
        
        outputList.append(bottomLeftLat)
        outputList.append(bottomLeftLon)
        outputList.append(bottomRightLon)
        outputList.append(topLeftLat)
        
        return outputList
    }
    
    func widenCoordinatesLastColFast(inputList: [IndividualAuroraSpot]) -> [IndividualAuroraSpot] {
        var outputList: [IndividualAuroraSpot] = []
        
        var LastList: [IndividualAuroraSpot] = []
        
        for item in 0...181 {
            LastList.append(inputList[item])
        }
        
        var appList: [IndividualAuroraSpot] = []
        
        for item in LastList {
            var tempAur = item
            
            tempAur.longitude = 360
            
            appList.append(tempAur)
        }
        
        outputList = inputList
        
        outputList.append(contentsOf: appList)
        
        return outputList;
    }
    
    // function to create extra spaces for outOfBound values that would be repeated, will help to create a simpler function.
    // Not Implemented.
    
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
    
    // function that based on tile coordinates will output all aurora values that would cover all tile with data
    
    func createTileAuroraList(inputTileCoordinateList: [Double],
                              inputAuroraList: [IndividualAuroraSpot],
                              zoom: Int,
                              calc: Bool) -> (inputList: [IndividualAuroraSpot],
                                             width: Int,
                                             height: Int,
                                             indexWidth: [Double],
                                             indexHeight: [Double]) {
        
        //        let start = BasicTimer().startTimer()
        
        // 10/3 upd - artefacts only on 180 longitude
        
        /*
         
         BREAK THIS FUNCTION DOWN
         for each step create a function, make them reusable. Create a separate module specifically for this
         
         apply this for each huge function!!!
         
         also look for values, a lot of them are seem to have duplicates, and duplicate calculations.
         
         for each function clean everything and move to a deparate file, comment each action to make sure it can be easily followed
         
         
         Put all of the sorting through other functions, then for parsing and updating data use a switch method.
         This will allow to optimize some steps and quicker get needed result.
         
         
         */
        
        
        // experimental fix - implement widen coordinates function.
        
        
        var latitudeList: [IndividualAuroraSpot] = [] // rename it, to make it more clear.
        
        // actual corner coordinates
        
        let topLatitude = inputTileCoordinateList[0]
        let bottomLatitude = inputTileCoordinateList[3]
        let maxLongitude = inputTileCoordinateList[2]
        let minLongitude = inputTileCoordinateList[1]
        
        // Outer boundaries for latitude and longitude describing a larger square where actual coordinates fit
    
        
        let celingLatitudeValue = topLatitude.rounded(.up)
        let floorLatitudeValue = bottomLatitude.rounded(.down)
        let startLongitudeValue = minLongitude.rounded(.down)
        let finishLongitudeValue = maxLongitude.rounded(.up) // this changes 359 to 360, avoid this
        
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
        
        // previous
        
        /*
         
         let differenceTopLat = topLatitude.rounded(.up) - topLatitude // topLatitude - topLatitude.rounded(.down)
         let differenceBottomLat = bottomLatitude - bottomLatitude.rounded(.down)
         let differenceLeftLon = minLongitude - minLongitude.rounded(.down) // ?
         
         // this one feels more accurate too
         
         let differenceRightLon = maxLongitude.rounded(.up) - maxLongitude
         
         */
        
        
        // previous method used!!!
        // (maxLongitude.rounded(.down) + 1.0) - maxLongitude
        
        
        // maxLongitude - maxLongitude.rounded(.down) - previous var.
        
        // maxLongitude.rounded(.up) - maxLongitude
        
        //        let latitudeSquaresCount = (topLatitude.rounded(.up) - bottomLatitude.rounded(.down))
        //        let longitudeSquaresCount = (maxLongitude.rounded(.up) - minLongitude.rounded(.down))
        
        var initialList: [IndividualAuroraSpot] = []
        var initialBackupList: [IndividualAuroraSpot] = []
        
        // var testChangedValuesList: [IndividualAuroraSpot] = []
        
        var allChangedLatitudeAuroraValues: [Double] = []
        var allChangedLongitudeAuroraValues: [Double] = []
        
        
        var updatedLatitudeAuroraValues: [IndividualAuroraSpot] = []
        var updatedLongitudeAuroraValues: [IndividualAuroraSpot] = []
        
        
        for aurora in inputAuroraList {
            // Cycle through list and append anything that fits inside tile.
            
            
            // maybe in future create a min_value_address and max_value_adress,
            // and based on this just input each element that is inbetween (too much extra data, look into it)
            
            if aurora.longitude >= startLongitudeValue && aurora.longitude <= finishLongitudeValue {
                if aurora.latitude >= floorLatitudeValue && aurora.latitude <= celingLatitudeValue {
                    latitudeList.append(aurora)
                    initialList.append(aurora)
                    initialBackupList.append(aurora)
                }
            }
        }
        
        let firstCornerLat = initialList[0].latitude // out ouf bound value, less than bottomLet
        let firstCornerLon = initialList[0].longitude // out of bound value, less that minLong
        
        let lastCornerLat = initialList[initialList.count - 1].latitude  // out of bound lat, highest
        let lastCornerLon = initialList[initialList.count - 1].longitude // out of bound, highest lon
        
        let differenceTopLat = lastCornerLat - topLatitude
        let differenceBottomLat = bottomLatitude - firstCornerLat
        let differenceLeftLon = minLongitude - firstCornerLon
        let differenceRightLon = lastCornerLon - maxLongitude
        
        //        let differenceTopLat = topLatitude.rounded(.up) - topLatitude // topLatitude - topLatitude.rounded(.down)
        //        let differenceBottomLat = bottomLatitude - bottomLatitude.rounded(.down)
        //        let differenceLeftLon = minLongitude - minLongitude.rounded(.down) // ?
        
        // this one feels more accurate too
        
        //        let differenceRightLon = maxLongitude.rounded(.up) - maxLongitude
        
        //        print()
        
        // Calculate Int for width and height.
        
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
        var allPreviousBottomBottomValues: [Double] = []
        var allPreviousBottomTopValues: [Double] = []
        
        var topIndex = height - 1
        // var topIndex = height - 1
        var bottomIndex = 0
        
        // rewrite to a function, avoid reusing two similar pieces of code, condense into a global function.
        
        for _ in 1...width {
            
            // this loop changes latitude values.
            // calculate top and bottom aurora.
            
            /*
             
             CRUCIAL
             
             1st - calculate arurora from inner to outer based on difference from 0...1 (next whole lat/lon)
             2nd - calculate new aurora from dots made on previous one
             
             
             
             */
            
            
            let bottomAuroraCoordinate = latitudeList[bottomIndex]
            var bottomAuroraValue = bottomAuroraCoordinate.aurora
            
            let nextAuroraValue = latitudeList[bottomIndex + 1].aurora
            
            // calculate new aurora difference applied to an aurora
            
            allPreviousBottomTopValues.append(nextAuroraValue)
            allPreviousBottomBottomValues.append(bottomAuroraValue)
            
            let bottomAuroraDifference = bottomAuroraValue - nextAuroraValue
            let changedBottomValue = bottomAuroraDifference * differenceBottomLat
            bottomAuroraValue = bottomAuroraValue - changedBottomValue // nextAuroraValue + changedBottomValue
            
            allChangedLatitudeAuroraValues.append(bottomAuroraValue)
            
            allChangedBottomValues.append(bottomAuroraValue)
            
            if bottomAuroraValue < 0 {
                print()
            }
            
            let newLeftAurora = IndividualAuroraSpot(longitude: bottomAuroraCoordinate.longitude,
                                                     latitude: bottomLatitude,
                                                     aurora: bottomAuroraValue)
            
            updatedLatitudeAuroraValues.append(newLeftAurora)
            
            let topCoordinateAurora = latitudeList[topIndex]
            var topAuroraValue = topCoordinateAurora.aurora
            let previousAuroraValue = latitudeList[topIndex - 1].aurora
            
            let topAuroraDifference = topAuroraValue - previousAuroraValue
            let changedTopValue = topAuroraDifference * differenceTopLat
            topAuroraValue = topAuroraValue - changedTopValue // previousAuroraValue + changedTopValue
            
            if topAuroraValue < 0 {
                print()
            }
            
            // create a list of new values and other values inbetween
            
            allChangedLatitudeAuroraValues.append(topAuroraValue)
            
            let newRightAurora = IndividualAuroraSpot(longitude: topCoordinateAurora.longitude,
                                                      latitude: topLatitude,
                                                      aurora: topAuroraValue)
            
            updatedLatitudeAuroraValues.append(newRightAurora)
            
            latitudeList[bottomIndex] = newLeftAurora
            latitudeList[topIndex] = newRightAurora
            
            topIndex = topIndex + (height)
            bottomIndex = bottomIndex + (height)
            
        }
        
        
        // creates a rectangle for each corner, not necessary for now.
        
        // creates a list with corner rectangle values (corner and one nearby for each direction)
        
        func calculateCornerValuesIndexes(inputWidth: Int, inputHeight: Int) -> [Int] {
            var outputIndexesList: [Int] = []
            // calculations will be done on order, to form 4 indexes. each 4 sets will represent
            // rectangle with bottomLeft, topLeft, bottomRight, topRight sides,
            
            // this method is good for big squares, for small ones it starts to break apart
            // rethink whole concept
            
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
            outputIndexesList.append((height * width) - (2 * height) + 1)
            outputIndexesList.append((height * width) - height)
            outputIndexesList.append(lastIndex - height + 2)
            
            
            outputIndexesList.append(lastIndex - height - 1)
            outputIndexesList.append(lastIndex - height)
            outputIndexesList.append(lastIndex - 1)
            outputIndexesList.append(lastIndex)
            
            return outputIndexesList
        }
        
        var cornerPixelList: [Int] = []
        
        var cornerAuroraValues: [IndividualAuroraSpot] = []
        var initialCornerAuroraValues: [IndividualAuroraSpot] = []
        
        cornerPixelList.append(contentsOf: calculateCornerValuesIndexes(inputWidth: width, inputHeight: height))
        
        // while values of corners here are untouched we can follow with some changes so later we can acuratley replace all corner values
        
        var bottomCutOffValues: [IndividualAuroraSpot] = []
        var originalListValues: [IndividualAuroraSpot] = []
        
        for item in cornerPixelList {
            
            originalListValues.append(initialList[item]) // all corner values in all changed list
            bottomCutOffValues.append(latitudeList[item])
        }
        
        // now we have a 16 value list with corner values that va can extract and use
        
        //print(originalListValues)
        //print(latitudeList)
        
        // bottom left corver value
        
        // write custom difference for each case?
        
        /*
        
        if originalListValues[2].longitude < minLongitude {
            print(originalListValues[2].longitude)
            print(minLongitude)
            print()
        }
        
        if originalListValues[8].longitude > maxLongitude {
            print(originalListValues[8].longitude)
            print(maxLongitude)
            print()
        }
        
         
         */
        // where I calculate corner values
        
        var auroraValuesList: [Double] = []
        
        let newLeftLonDiff = originalListValues[2].longitude - minLongitude
        let newRightLonDiff = maxLongitude - originalListValues[8].longitude
        
        let leftBottomCornerDifference = bottomCutOffValues[0].aurora - bottomCutOffValues[2].aurora
        // was differenceLeftLon
        let leftBottomCornerFinalVal = (leftBottomCornerDifference * newLeftLonDiff) + bottomCutOffValues[2].aurora
        
        auroraValuesList.append(leftBottomCornerFinalVal)
        
        // ceiling value difference
        let leftTopCornerDifference = bottomCutOffValues[5].aurora - bottomCutOffValues[7].aurora
        // was differenceLeftLon
        let leftTopCornerFinalVal = (leftTopCornerDifference * newLeftLonDiff) + bottomCutOffValues[7].aurora
        
        auroraValuesList.append(leftTopCornerFinalVal)
        
        // flip sides for now
        
        let rightBottomCornerDifference = bottomCutOffValues[10].aurora - bottomCutOffValues[8].aurora
        // was differenceRightLon
        let rightBottomCornerFinalVal = (rightBottomCornerDifference * newRightLonDiff) + bottomCutOffValues[8].aurora
        
        auroraValuesList.append(rightBottomCornerFinalVal)
        
        let rightTopCornerDifference = bottomCutOffValues[15].aurora - bottomCutOffValues[13].aurora
        // was differenceRightLon
        let rightTopCornerFinalVal = (rightTopCornerDifference * newRightLonDiff) + bottomCutOffValues[13].aurora
        
        //print(leftBottomCornerFinalVal)
        //print()
        
        auroraValuesList.append(rightTopCornerFinalVal)
        
        for item in auroraValuesList {
            if item < 0 {
                print()
            }
        }
        
        var rightIndex = height * (width - 1)
        var leftIndex = 0
        
        
        for _ in 1...(height) {
            
            // declare aurora coordinate and aurora value
            
            // replaced latitudelist with initialList
            
            
            let leftAuroraCoordinate = initialList[leftIndex]
            var leftAuroraValue = leftAuroraCoordinate.aurora
            let nextLeftAuroraValue = initialList[leftIndex + height].aurora
            
            // strong zoom around 359 our of bound, parse data to account for this
            
            
            let leftAuroraDifference = leftAuroraValue - nextLeftAuroraValue
            let changedLeftValue = leftAuroraDifference * differenceLeftLon // leftLon, since we comparing edge values
            leftAuroraValue = leftAuroraValue - changedLeftValue // changedLeftValue + nextLeftAuroraValue
            
            if leftAuroraValue < 0 {
                print()
            }
            
            // create a new individual spot with a new value
            
            allChangedLongitudeAuroraValues.append(leftAuroraValue)
            
            let newBottomAurora = IndividualAuroraSpot(longitude: minLongitude,
                                                       latitude: latitudeList[leftIndex].latitude,
                                                       aurora: leftAuroraValue)
            
            updatedLongitudeAuroraValues.append(newBottomAurora)
            
            // declare aurora coordinate and new aurora value
            
            
            let topRightCoordinate = initialList[rightIndex]
            var rightAuroraValue = topRightCoordinate.aurora
            let previousRightAuroraCoordinate = initialList[rightIndex - height] // temo comparison
            let PreviousRightAurora = initialList[rightIndex - height].aurora
            
            var tempRightDiff = 0.0
            
            /*
             
             Problem here is difference between 359 ans 360 is crucial.
             I would need to make sure all of my used values are withing the requested range
             
             looks like i have 0 -> 359 comparing to 0 -> 360.
             
             */
            
            if maxLongitude == 360 {
                tempRightDiff = differenceRightLon + 1 // terrible. Im proud of it
            } else {
                tempRightDiff = differenceRightLon
            }
            
            let rightAuroraDifference = rightAuroraValue - PreviousRightAurora // was rightAuroraValue - previous
            let changedRightValue = rightAuroraDifference * differenceRightLon // rightLon? change to lat
            rightAuroraValue = rightAuroraValue - changedRightValue // changedRightValue + PreviousRightAurora
            
            if rightAuroraValue < 0 {
                print()
            }
            
            // allChangedLongitudeAuroraValues.append(rightAuroraValue)

            var tempVal = 0.0
            
            if maxLongitude >= 360 {
                tempVal = 359
            } else {
                tempVal = maxLongitude
            }
            
            let newTopAurora = IndividualAuroraSpot(longitude: maxLongitude,
                                                    latitude: latitudeList[rightIndex].latitude,
                                                    aurora: rightAuroraValue)
            
            // updatedLongitudeAuroraValues.append(newTopAurora)
            
            latitudeList[leftIndex] = newBottomAurora
            latitudeList[rightIndex] = newTopAurora
            
            // we are changing first width and last width values, so BOTTOM and TOP of a rectangle
            
            leftIndex = leftIndex + 1
            rightIndex = rightIndex + 1
        }
        
        // finalization of corner values up to a certain size. later needs to be improved.
        
        latitudeList[0].aurora = leftBottomCornerFinalVal // finalBottomLeftAurora
        latitudeList[height - 1].aurora = leftTopCornerFinalVal // finalTopLeftCorner
        latitudeList[latitudeList.count - height].aurora = rightBottomCornerFinalVal // finalBottomRightCorner
        latitudeList[latitudeList.count - 1].aurora = rightTopCornerFinalVal // finalTopRightCorner
        
        
        
        // Accuracy method, will be changed later to avoid this step.
        // does it even help? - apparently lmao
        
        /*
        if maxLongitude >= 360 {
            var cycleIndex = 0
            for item in latitudeList {
                if item.longitude >= 360 {
                    let newItem = IndividualAuroraSpot(longitude: 359.0, latitude: item.latitude, aurora: item.aurora)
                    latitudeList[cycleIndex] = newItem
                    print()
                }
                cycleIndex += 1
            }
        }
        */
         
        
        // when the amount in main lists is less than 16, calculations are not correct due to square calculation system
        
        /*
         
         as of now i would need to write later all conditions and why 16 point system can fail on some of them
         
         then i should account for al cases and figure a most optiman way for each, this should help
         
         for smaller zooms in that area go through cases and see why some things are consistently breaking
         
         */
        
      
        
        /*

        // create values with indexes, process them?
        
        var initialValuesList: [Double] = []
        // var finalValuesList: [Double] = []
        
        for item in cornerPixelList {
            
            
            initialCornerAuroraValues.append(initialList[item]) // all corner values in all changed list
            cornerAuroraValues.append(latitudeList[item])
            initialValuesList.append(initialBackupList[item].aurora)
        }
        
         */
//        print(initialCornerAuroraValues)
//        print(cornerAuroraValues)
//        print(initialValuesList)
        
        // special case when there are only 4 corner values, and whole rectangle is inside whole coorindate bound.
        
        if latitudeList.count == 4 { // within 1 coordinate
            
            // also write similar stuff for case when width is 2, and height is more that 2 (stretched latitude)
            
            // unique condition, can be used overall for any 2 sided things.
            
            // even this might be redundant.
            
            // leave this function for later
            
            // This is also all incorrect i think?
            
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

        
         
        // Create new coordinates with ratios through mercator, 0...255

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
        /*
        if latitudeList.count < 20 {
            print(latitudeList)
            print(initialBackupList)
            print()
            
        }
         */
        
//        BasicTimer().endTimer(start, functionName: "createTileAuroraList")
        
        for aurora in latitudeList {
            if aurora.aurora < 0 {
                print()
            }
        }
        
        if calc == true {
            print()
        }
        
        return (latitudeList, width, height, indexWidth, indexHeight)
    }
    
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
    
    // Complex function that returns tile png.
    
    func createRectanglePNG(inputList: [IndividualAuroraSpot],
                            width: Int,
                            height: Int,
                            indexWidth: [Double],
                            indexHeight: [Double],
                            maxAurora: Double,
                            calc: Bool) -> CGImage {
        
        // Would be simplified in future.
        
//        let start = BasicTimer().startTimer()
        
        var testList: [IndividualAuroraSpot] = []
        var newIndexHeight: [Double] = []
        newIndexHeight = indexHeight.reversed()
        var auroraIndex = 0

        
        let rotatedList = rotateList(inputList: inputList, height: height, width: width)

        for latitude in newIndexHeight {
            var originalFlip: [IndividualAuroraSpot] = []
            for longitude in indexWidth {
                let newCorrdinate = IndividualAuroraSpot(longitude: Double(longitude),
                                                         latitude: Double(latitude),
                                                         aurora: rotatedList[auroraIndex].aurora)
                auroraIndex = auroraIndex + 1
                originalFlip.append(newCorrdinate)
                
            }

            testList.append(contentsOf: originalFlip)
            
            originalFlip = []
        }

        // create an aurora values list.
        
        let auroraQuickList = testList.map { $0.aurora }
        
        // create an empty list that will return an empty picture.
        
        var emptyList: [Double] = []
        
        for _ in 0...((256 * 256) - 1) {
            emptyList.append(0.0)
        }
        
        var gradientPixelArray: [Double] = []
 
        // Cycle through list, see if there are any aurora values, if there are - create a picture, else pass an empty list
        
        for aurora in inputList {
            if aurora.aurora < 0.0 {
                print(aurora)
                print()
            }
        }
        
        for aurora in auroraQuickList {
            if aurora < 0.0 {
                print(aurora)
                print()
            }
        }
 
        for aurora in testList {
            if aurora.aurora < 0.0 {
                print(aurora)
                print()
            }
        }
        
        for aurora in auroraQuickList {
            if aurora != 0 {
                
                let experiment = createGradientList(inputList: testList,
                                                    height: height,
                                                    width: width,
                                                    heightIndex: newIndexHeight,
                                                    widthIndex: indexWidth,
                                                    calc: calc)

                gradientPixelArray = experiment
                break
            } else {
                gradientPixelArray = emptyList
            }
        }
        
        // Create an empty UInt32 list, that will be used to fill with actual color value.
        
        var pixelGrid: [UInt32] = []
        
        // var auroraAlpha: Double = 0
        
        if maxAurora != 0 {
            let auroraAlpha = 1.0 / maxAurora // this is amount of increments from 0 to 1 based on aurora strength
        }
        
        // Create color scheme for overlay image
        
        let color = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.0)
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        // For each gradient value add either a value or an empty pixel

        /*
         
         original color.
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32((currentAuroraAlpha) * 255.0) << 24 + // for filled tiles switch to 1
             UInt32((blue) * 255.0) << 16 +
             UInt32((1) * 255.0) << 8 + // for filled tiles switch to currentAuroraAlpha
             UInt32(alpha * 255.0)
             
             pixelGrid.append(newColor)
             
         }
         
         */
        
        var emptyColor: UInt32 = 0
        
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            emptyColor += UInt32(0 * 255.0) << 24 + // put 0 for empty spots not filled with anything
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
        
        // in case of incorrect values.
        
        var calcIndex = 0
        /*
        for item in gradientPixelArray {
            if item < 0.0 || item.isNaN {
                print(item)
                
                print(gradientPixelArray[calcIndex...calcIndex+100])
                print()
                }
            calcIndex = calcIndex + 1
        }
        */
        // cycling through values and appending a value to a colorl list based on value from Aurora Double List.
        
        // create an accurate representation
        
        // 0...10...50...90...100
        
        var negativeValuesCount = 0

        for item in gradientPixelArray {
            if item >= 100 {
                
                // Red
                
                var newColor: UInt32 = 0
                
                if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    newColor += UInt32(1.0 * 255.0) << 24 +
                    UInt32(blue * 255.0) << 16 +
                    UInt32(green * 255.0) << 8 +
                    UInt32(1.0 * 255.0)
                    
                    pixelGrid.append(newColor)
                }
                
            } else if item > 90 {
                
                // make orange -> red
                
                var newColor: UInt32 = 0
                
                let colorGradientValue = Double(item - 90) / 10  //34 // 1...
                
                if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    newColor += UInt32(1.0 * 255.0) << 24 +
                    UInt32(blue * 255.0) << 16 +
                    UInt32((0.5 - (colorGradientValue / 2)) * 255.0) << 8 +
                    UInt32(1.0 * 255.0)
                    
                    pixelGrid.append(newColor)
                }
                
            } else if item > 50 {
                
                // make yellow -> orange
                
                var newColor: UInt32 = 0
                
                let colorGradientValue = Double(item - 50) / 40  //34 // 1...
                
                if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    newColor += UInt32(1.0 * 255.0) << 24 +
                    UInt32(blue * 255.0) << 16 +
                    UInt32((1.0 - (colorGradientValue / 2)) * 255.0) << 8 +
                    UInt32(1.0 * 255.0)
                    
                    pixelGrid.append(newColor)
                }
                
            } else if item > 10 {
                
                // Green -> Yellow
                
                var newColor: UInt32 = 0
                
                let colorGradientValue = Double(item - 10) / 40 // 1...30 values used for gradient increment // 66?
                
                if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    newColor += UInt32(1.0 * 255.0) << 24 + // (1.0 - currentAuroraAlpha)
                    UInt32(blue * 255.0) << 16 +
                    UInt32(1.0 * 255.0) << 8 +
                    UInt32((0.5 + (colorGradientValue / 2)) * 255.0)
                    
                    pixelGrid.append(newColor)
                    
                }
                
            } else if item > 0 {
                
                // Make alpha -> Green
                
                var newColor: UInt32 = 0
                
                let colorGradientValue = Double(item) / 10 // 1...30 values used for gradient increment
                
                if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    newColor += UInt32(colorGradientValue * 255.0) << 24 + // current was before
                    UInt32(blue * 255.0) << 16 +
                    UInt32(1.0 * 255.0) << 8 +
                    UInt32((colorGradientValue / 2) * 255.0)
                    
                    pixelGrid.append(newColor)
                    
                }
                
            } else if item < 0.0 {
                // negative values mean error in calculations.
                
                // would need to figure why this happens, tiles to pay attention to: 4_15_10, 4_15_11.x
                
                // would be a good idea to take a look at lists.
                
                // Red
                
                negativeValuesCount += 1
                
                var newColor: UInt32 = 0
                
                if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    newColor += UInt32(1.0 * 255.0) << 24 +
                    UInt32(blue * 255.0) << 16 +
                    UInt32(green * 255.0) << 8 +
                    UInt32(1.0 * 255.0)
                    
                    pixelGrid.append(newColor)
                }
                
                // print(item)
            } else {
                pixelGrid.append(emptyColor)
            }
            
        }
        
        if negativeValuesCount != 0 {
            print("I managed to get \(negativeValuesCount) empty values!")
        }
        
        // Duplicate for rotateList func.
        
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
        // not implemented anymore.
        
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
        
        // Oreientation for a bitmap picture is topLeft -> topRight, bottomLeft -> bottomRight.
        // Current list oreitntation is topLeft -> bottomLeft
        
        // Creates a picture and returns a Core Graphics Image.
        
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
        
        let finalImage = createSimpleImage(inputList: pixelGrid)
        
        // BasicTimer().endTimer(start, functionName: "createRectanglePNG")

        
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
                if aurora.latitude >= bottomLatitude && aurora.latitude <= topLatitude { // latitude check
                    outputList.append(aurora)
                }
            }
        }
        
        return outputList
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
    
    // New function, replacing parseMerc and createGRadient
    // new function will save on processing, and should be more omptimal.
    // It would accept updated coordinate grid, and create list for a picture, or a picture in future
    
    func createGradientList(inputList: [IndividualAuroraSpot],
                            height: Int,
                            width: Int,
                            heightIndex: [Double],
                            widthIndex: [Double],
                            calc: Bool) -> [Double] {
        
//        let start = BasicTimer().startTimer()
        
        /*
         
         Current function plan:
         
         1. Accept list with coordinates spread to 0...255 range
         2. Rotate list 90 Degress while its relatively small // passing already rotated list
         3. For each Height value create a list with width values, changing width value to incremental difference
         4. Create a list of 0 size 256 items. This would be an initial Line list
         5. For each Height value create a list with width values, each longitude index == position on line list, fill aurora
         6. for each list, for each width replace 0 with appropriate values calculated based of difference
         7. Append all lists into one.
         
         */

        // initialize a width column list
        
        // Create a list with Longitude and latitude values from 0 to 255, fill other coordinates with 0 inbetween
        // Each list will be used as a template for column and rows to be filled with values for each 0 value between coordinats.
        
        for aurora in inputList {
            if aurora.aurora < 0.0 {
                print(aurora)
                print()
            }
        }
        
        var widthList: [Double] = []
        var heightList: [Double] = []
        
        widthList = widthIndex
        heightList = heightIndex
        
        var auroraColumnList: [Double] = []
        var auroraRowList: [Double] = []

        
        for item in inputList[0...(width - 1)] {
            auroraRowList.append(item.aurora)
        }
        
        auroraColumnList.append(inputList[0].aurora)
        
        for item in 1...height - 1 {
            auroraColumnList.append(inputList[item * width].aurora)
        }
        
        var rowList: [Double] = []
        var emptyZeroList: [Double] = []
        
        for _ in 0...255 {
            rowList.append(0.0)
            emptyZeroList.append(0.0)
        }
        
        var cycleIndex = 0
        
        cycleIndex = 0
        
        for item in widthList {
            rowList[Int(item)] = auroraRowList[cycleIndex]
            cycleIndex += 1
        }

        // Creates a list of empty spots between values, that will be filled with gradient
        
        func differenceBetweenCoordinateValues(inputFuncList: [Double]) -> [Int] {
            var processedList = inputFuncList
            
            var previousDistanceDifferenceValue = 255.0
            var firstZero = false
            
            if processedList[0] != 255.0 {
                processedList = processedList.reversed()
                firstZero = true
                
            }
            
            var distanceDifferenceList: [Int] = []
            
            for item in processedList {
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
   
        
        var secondAuroraColumnList: [Double] = []
        
        for item in inputList[height...((height * 2) - 1)] {
            secondAuroraColumnList.append(item.aurora)
        }
        
        // list with original aurora values, each list inside a list is a column
        
        var listWithOriginaHeighValues: [[Double]] = []
        var tempRowList: [Double] = []
        
        // create a loop that will loop WidthTimes to append Height columns with values
        // also create a list with coordinate values

        
        for row in 0...(height - 1) {
            for item in inputList[(width * row)...((width * (row + 1)) - 1)] {
                tempRowList.append(item.aurora)
                
            }
            listWithOriginaHeighValues.append(tempRowList)
            
            tempRowList = []
        }
        
        // creates a count of zeros bertween values based on coordinates.

        let zeroRowCount = differenceBetweenCoordinateValues(inputFuncList: widthList)
        let zeroColumnCount = differenceBetweenCoordinateValues(inputFuncList: heightList)

        
        
        /*
         
         to create gradient, we have at least 3 coordinate values, and 2 aurora values
         each whole value will be in the end and in the beginning
         append first item, then cycle through a list and append other items
         
         
         */
        
        // Creates a list with columns
        
        var newGradientColumnList: [[Double]] = []
        
        // append first list to a new list
        
        newGradientColumnList.append(listWithOriginaHeighValues[0])
        
        var nextRowListIndex = 1
        
        // Main cycle for creating 256 columns with Gradient values.
        
        for item in zeroColumnCount { // zeroCountList
            // for each zero value i will create gradient lists, and append them min value is 1, max value is 255
            // calculate how many times it will cycle
            // current and previous lists with values
            
            // count for gradients values:
            
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
                
                
                var listOfAppendingValues: [[Double]] = []
                
                for increment in 0...item {
                    // new empty list that we will append values to
                    var newListItemIndex = 0
                    var appendingNewValuesList: [Double] = []
                    // here goes main cycle
                    // for each value in current list, add increments, from 0 to last item
                    
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
                }
                
                newGradientColumnList.append(contentsOf: listOfAppendingValues.reversed())
                
            } else {
                // append next thing
                
                newGradientColumnList.append(listWithOriginaHeighValues[nextRowListIndex])
            }

            nextRowListIndex += 1
        }
        
        if newGradientColumnList.count > 256 {
            //ONLY TEMP
            newGradientColumnList.remove(at: newGradientColumnList.count - 1)
        }
        

        // cycle through each list with a create gradient function and return a main list
        
        var finalOutputList: [Double] = []
        
        // for each column creates a list with filled gradient values
        
        for list in newGradientColumnList {
            let newGradientList = fillLineWithGradient(inputLine: list, lengthZeros: zeroRowCount) //zeroRowCount
            
            for item in newGradientList {
                if item < 0 {
                    print()
                }
            }
            
            finalOutputList.append(contentsOf: newGradientList)
        }
        
        if finalOutputList.count != 65536 {
            
            // calculations error.
            
            //print(finalOutputList.count)
            //print(newGradientColumnList)
            
            let deleteIndex = 65536
            
            let upperRange = finalOutputList.count
            
            // temp solution, was used before.
            
            for _ in 65536...upperRange - 1 {
                finalOutputList.remove(at: deleteIndex)
            }
            
            print(heightIndex)
            print(widthIndex)
            print(finalOutputList.count)
            print()
        }
        
        // function to fill a line with gradient

        func fillLineWithGradient(inputLine: [Double], lengthZeros: [Int] ) -> [Double] {
            // cycle through each item, if it's non zero, append
            // if it is zero, create /empty spots/ times values list and append

            var outputList: [Double] = []
            
            var wholeActualNum = inputLine[0]
            
            var itemAddedCount = 0
            
            var wholeValue = true
            
            // cycle through each item, check if it's whole. Use previous function as an example
            
            for item in inputLine {
                
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
                        

                        
                        for number in 0...lineFillItems - 1 {
                            
                            let newValue = previousValue + (Double(number + 1) * incrementVal)
                            
                            newLineList.append(newValue)
                            
                        }
                        
                        outputList.append(contentsOf: newLineList)
                        
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

            return outputList // .reversed()
        }
        
        /*
         
        In case of errors, can be used to create e file with output values.
        
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

         */
    
  

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
        /*
        if calc {
            print()
        }
         */
        // BasicTimer().endTimer(start, functionName: "createGradient")
        
        return finalOutputList
    }
    
}
    
/*
 
 for item in gradientPixelArray {
     if item >= 100 {
         var newColor: UInt32 = 0
         let currentAuroraAlpha = Double(item) * auroraAlpha
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32(currentAuroraAlpha * 255.0) << 24 +
             UInt32(blue * 255.0) << 16 +
             UInt32(green * 255.0) << 8 +
             UInt32(1.0 * 255.0)
             
             pixelGrid.append(newColor)
         }
         
     } else if item >= 60 && item < 100 {
         var newColor: UInt32 = 0
         let currentAuroraAlpha = Double(item) * auroraAlpha
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32(currentAuroraAlpha * 255.0) << 24 +
             UInt32(blue * 255.0) << 16 +
             UInt32((1.0 - currentAuroraAlpha) * 255.0) << 8 +
             UInt32(1.0 * 255.0)
             
             pixelGrid.append(newColor)
         }
         
     } else if item >= 30 && item < 60 {
         var newColor: UInt32 = 0
         let currentAuroraAlpha = Double(item) * auroraAlpha
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32(currentAuroraAlpha * 255.0) << 24 + // (1.0 - currentAuroraAlpha)
             UInt32(blue * 255.0) << 16 + // red
             UInt32(1.0 * 255.0) << 8 + // green?
             UInt32((1.0 - currentAuroraAlpha) * 255.0) // blue?
             
             pixelGrid.append(newColor)
             
         }
         
     } else if item > 0 && item < 30 {
         var newColor: UInt32 = 0
         let currentAuroraAlpha = Double(item) * auroraAlpha
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32((currentAuroraAlpha) * 255.0) << 24 + // current was before
             UInt32(blue * 255.0) << 16 +
             UInt32(currentAuroraAlpha * 255.0) << 8 +
             UInt32(alpha * 255.0)
             
             pixelGrid.append(newColor)
             
         }
         
     } else if item < 0.0 {
         // negative values mean error in calculations.
         print(item)
     } else {
         pixelGrid.append(emptyColor)
     }
     
 }

 
 
 
 for item in gradientPixelArray {
     if item >= 100 {
         
         // Create a new gradient line and make it orange -> Red
         
         
         var newColor: UInt32 = 0
         let currentAuroraAlpha = Double(item) * auroraAlpha
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32(1.0 * 255.0) << 24 +
             UInt32(blue * 255.0) << 16 +
             UInt32(green * 255.0) << 8 +
             UInt32(1.0 * 255.0)
             
             pixelGrid.append(newColor)
         }
         
     } else if item >= 66 && item < 100 {
         
         // make Yellow -> Orange
         
         var newColor: UInt32 = 0
         let currentAuroraAlpha = Double(item) * auroraAlpha
         
         let colorGradientValue = Double(item - 66.0) / 34  //34 // 1...
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32(1.0 * 255.0) << 24 +
             UInt32(blue * 255.0) << 16 +
             UInt32((1.0 - colorGradientValue) * 255.0) << 8 +
             UInt32(1.0 * 255.0)
             
             pixelGrid.append(newColor)
         }
         
     } else if item > 34 && item < 66 {
         
         
         var newColor: UInt32 = 0
         let currentAuroraAlpha = Double(item) * auroraAlpha
         
         let colorGradientValue = Double(item - 34.0) / 34 // 1...30 values used for gradient increment // 66?
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32(1.0 * 255.0) << 24 + // (1.0 - currentAuroraAlpha)
             UInt32(blue * 255.0) << 16 +
             UInt32(1.0 * 255.0) << 8 +
             UInt32(colorGradientValue * 255.0)
             
             pixelGrid.append(newColor)
             
         }
         
     } else if item > 0 {
         
         // Make green -> Yellow
         
         var newColor: UInt32 = 0
         let currentAuroraAlpha = Double(item) * auroraAlpha
         
         let colorGradientValue = Double(item) / 34 // 1...30 values used for gradient increment
         
         if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
             newColor += UInt32(colorGradientValue * 255.0) << 24 + // current was before
             UInt32(blue * 255.0) << 16 +
             UInt32(colorGradientValue * 255.0) << 8 +
             UInt32(0.0 * 255.0)
             
             pixelGrid.append(newColor)
             
         }
         
     } else if item < 0.0 {
         // negative values mean error in calculations.
         print(item)
     } else {
         pixelGrid.append(emptyColor)
     }
     
 }
 
 */
