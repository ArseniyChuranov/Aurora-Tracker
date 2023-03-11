//
//  ContentView.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//

import SwiftUI
import MapKit
import QuartzCore // ?????

struct ContentView: View {
    
    @EnvironmentObject var provider: AuroraProvider
    private let downloader = TestDownloader()
    private let client = AuroraClient()
    @State private var newList: [IndividualAuroraSpot] = []
    @State private var newPolygonList: [CLLocationCoordinate2D] = []
    
    @State private var newColorList: [UInt32] = []
    
    @State private var error: AuroraError?
    @State private var hasError = false
    
    let coordinateCalculate = CoordinateCalculations()

    var body: some View {
        VStack {
            AuroraMapView(auroraList: $newList)
                .ignoresSafeArea(.all)
            
        }
//        .padding()
        .task() {
            await fetchAurora()
            
            //let thridLevelList = convertIncomingData(inputList: newList, resolution: 2048)
            
            //SaveAuroraTiles().generateGridTilePicture(inputList: thridLevelList, resolution: 2048, zoomLevel: 3)
            
            // Inefficient method for now, will be replaced with a better one later.
            
            /*
            
            let thridLevelList = convertIncomingData(inputList: newList, resolution: 2048)
            
            SaveAuroraTiles().generateGridTilePicture(inputList: thridLevelList, resolution: 2048, zoomLevel: 3)
            
            let fourthLevelList = convertIncomingData(inputList: newList, resolution: 4096)
            
            SaveAuroraTiles().generateGridTilePicture(inputList: fourthLevelList, resolution: 4096, zoomLevel: 4)
             
             */
            
            // this function will try to save document to a correct directory
            // SaveAuroraTiles().generateGridTilePicture(inputList: newColorList, resolution: 1024, zoomLevel: 2)
        }
    }
}

extension ContentView {
    
    
    func convertIncomingData(inputList: [IndividualAuroraSpot], resolution: Int) -> [UInt32] {
        
        // Find max aurora value:
        
        
        
        let auroraList = inputList.map {$0.aurora}
        let maxAurora = auroraList.max()
        
        let auroraAlpha = 1 / maxAurora! // this is amount of increments from 0 to 1 based on aurora strength
        
        // Create color scheme for overlay image
    
        let color = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.0)
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
  
        var filteredAuroraList: [IndividualAuroraSpot] = []
        
        // Take raw value and filter anything above above 86 and below -86 // later change for exact max tile value possible by Mercator,
        // as of now it doesnt really matter.
        
        for aurora in inputList {
            if aurora.latitude < 86 && aurora.latitude > -86 {
                filteredAuroraList.append(aurora)
            }
        }
        
        
        var mercatorSphereCoordinates: [IndividualAuroraSpot] = []
        
        // Convert globe coordinates grid to Mercator ptojection coordinates
        
        for aurora in filteredAuroraList {
            
            let result = latLonToMercatonSecond(inputLatitude: aurora.latitude, inputLongitude: aurora.longitude, resolution: resolution)
            
            let lat: Double = result.outputLatitude
            let lon: Double = result.outputLongitude
            
            mercatorSphereCoordinates.append(IndividualAuroraSpot(longitude: lon, latitude: lat, aurora: aurora.aurora))
        }
        
        
//        print(mercatorSphereCoordinates[0...100])
//        print("og mercator sphere coordinates")
        
        /*
         
            Create a list filled with structure that represent a Rectangle with coordinate as corners and aurora values as corners.
            Each strcuture's value will allow to create a rectangle that will be filled with gradient for smooth representation.
         
         */
        
        let rectangleResult = parseMercatorToRectangles(mercatorGrid: mercatorSphereCoordinates, resolution: resolution)
        
//        print(rectangleResult[0...100])
//        print("og rectangles results")
        
        func parseMercatorToRectangles(mercatorGrid: [IndividualAuroraSpot], resolution: Int) -> ([AuroraCoordinateRectangle]) {
            var outputRectangleList: [AuroraCoordinateRectangle] = []
            /*
             Plan:
                1. Сycle through a total amount of elements to create a struct with a rectangle corners.
                2. Based on certain conditions execute one of 4 scenarios
                3. Filter and append only structs that have any Aurora value that is not 0, if all 4 are zeros,
                    it would be an empty rectangle without gradient.
             
             */

       
            var beginningIndex = 0
            var tempIndexSkip = 0
            
            var latitudeIndex = 0
            var longitudeIndex = 0

              
            for aurora in 0...61559 { // later change to total list count.
                
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

                if latitudeIndex == 170 {
                    
                    // End of Latitude index, start counting again.
                    
                    latitudeIndex = 0
                    tempIndexSkip = tempIndexSkip + 1
                    
                    // 0...170 = 171 items
                    // 171...341 = 171 + 171 items
                    // 342...512 = 171 + 171 + 171 items
                    
                    
                } else {
                    
                    // 0...170, count and add
                    
                    if longitudeIndex == 359 {
                        
                        // Last longitude line, index will be out of bound, so for each longitude a value from 0 to 359 will be provided
                        // All latitude values will be normal, only longitude values will be different
                        // Also check for last latitude value here
                        // For coordinates just use resolution value
                        
                        if latitudeIndex == 169 {
                            
                            // beginning index = 0..359
                            
                            // Last iteration of a func here
                            
                            AuroraBottomLeftCorner = mercatorGrid[aurora].aurora
                            AuroraTopLeftCorner = mercatorGrid[aurora + 1].aurora
                            AuroraBottomRightCorner = mercatorGrid[beginningIndex].aurora
                            AuroraTopRightCorner = mercatorGrid[beginningIndex + 1].aurora
                            
                            
                            BottomLeftCornerLat = mercatorGrid[aurora].latitude
                            BottomleftCornerLon = mercatorGrid[aurora].longitude
                            BottomRightCorner = Double(resolution)
                            TopLeftCorner = mercatorGrid[aurora + 1].latitude
                            
                            latitudeIndex = latitudeIndex + 1
                            beginningIndex = beginningIndex + 1
                            
                            
                            
                        } else {
                            
                            // beginning index = 0..359
                            
                            AuroraBottomLeftCorner = mercatorGrid[aurora].aurora
                            AuroraTopLeftCorner = mercatorGrid[aurora + 1].aurora
                            AuroraBottomRightCorner = mercatorGrid[beginningIndex].aurora
                            AuroraTopRightCorner = mercatorGrid[beginningIndex + 1].aurora
                            
                            BottomLeftCornerLat = mercatorGrid[aurora].latitude
                            BottomleftCornerLon = mercatorGrid[aurora].longitude
                            BottomRightCorner = Double(resolution)
                            TopLeftCorner = mercatorGrid[aurora + 1].latitude
                            
                            beginningIndex = beginningIndex + 1
                            latitudeIndex = latitudeIndex + 1
                            
                        }
                        
                        let resultRectangle = AuroraCoordinateRectangle(id: UUID(),
                                                                        coordinateList: [BottomLeftCornerLat,
                                                                                         BottomleftCornerLon,
                                                                                         BottomRightCorner,
                                                                                         TopLeftCorner],
                                                                        auroraList: [AuroraBottomLeftCorner,
                                                                                     AuroraBottomRightCorner,
                                                                                     AuroraTopLeftCorner,
                                                                                     AuroraTopRightCorner])
                        
                        // If any of Aurora values in list is not zero, add toa list.
                        
                        for auroraValue in resultRectangle.auroraList {
                            if auroraValue != 0 {
                                outputRectangleList.append(resultRectangle)
                                break
                            }
                        }
                        
                        
                        
                    } else {
                        
                        // longitude index 0...358
                        
                        if latitudeIndex == 169 {
                            // 0...170, 171...
                            // Last rectangle in the Latitude line
                            // I might instead follow a differnt path, since I won't be needing to cycle through each aurora,
                            // i would need less value
                            // longitudeIndex will be used to determine Longitude Count, 0...359
                            
                            AuroraBottomLeftCorner = mercatorGrid[aurora].aurora
                            AuroraTopLeftCorner = mercatorGrid[aurora + 1].aurora
                            AuroraBottomRightCorner = mercatorGrid[aurora + 171].aurora
                            AuroraTopRightCorner = mercatorGrid[aurora + 172].aurora
                            
                            BottomLeftCornerLat = mercatorGrid[aurora].latitude
                            BottomleftCornerLon = mercatorGrid[aurora].longitude
                            BottomRightCorner = mercatorGrid[aurora + 171].longitude
                            TopLeftCorner = mercatorGrid[aurora + 1].latitude
                            
                            latitudeIndex = latitudeIndex + 1
                            longitudeIndex = longitudeIndex + 1
                            
                            
                        } else {
                            
                            // latitude index 0...169
                            
                            AuroraBottomLeftCorner = mercatorGrid[aurora].aurora
                            AuroraTopLeftCorner = mercatorGrid[aurora + 1].aurora
                            AuroraBottomRightCorner = mercatorGrid[aurora + 171].aurora
                            AuroraTopRightCorner = mercatorGrid[aurora + 172].aurora
                            
                            BottomLeftCornerLat = mercatorGrid[aurora].latitude
                            BottomleftCornerLon = mercatorGrid[aurora].longitude
                            BottomRightCorner = mercatorGrid[aurora + 171].longitude
                            TopLeftCorner = mercatorGrid[aurora + 1].latitude
                            
                            latitudeIndex = latitudeIndex + 1
                            
                            
                        }
                        
                        let resultRectangle = AuroraCoordinateRectangle(id: UUID(),
                                                                        coordinateList: [BottomLeftCornerLat,
                                                                                         BottomleftCornerLon,
                                                                                         BottomRightCorner,
                                                                                         TopLeftCorner],
                                                                        auroraList: [AuroraBottomLeftCorner,
                                                                                     AuroraBottomRightCorner,
                                                                                     AuroraTopLeftCorner,
                                                                                     AuroraTopRightCorner])
                        
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

        
        /*
         
        Test that proofs there are no nonAuroraValues in list
         
        var totalNumRect = rectangleResult.count
        
        for item in 0...(totalNumRect - 1) {
            if rectangleResult[item].auroraList.contains([0.0, 0.0, 0.0, 0.0]) {
                print(rectangleResult[item])
                print("Found empty value")
            }
        }
         
        */

        // Create 2 lists, one with gradiend value for each pixel, another it's location on a total grid.
        // Each index of gradient will be equal to index of a position.
        
        var gradientTestValuesList: [Double] = []
        var gradientTestIndexList: [Int] = []
        
        // Cycle throigh rectangle struct list and "fill rectangle with gradient" as well as store location for each pixel.
     
        for item in rectangleResult {
            let gradientProduct = createGradientRectangle(inputRectangle: item, resolution: resolution)
            
            gradientTestValuesList.append(contentsOf: gradientProduct.valueList)
            gradientTestIndexList.append(contentsOf: gradientProduct.indexList)

        }
        
        //print(rectangleResult)
        
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
            
            
            
            
            
            
            
            
            
            /*
             
            Previous method, wrong since creates 2 different lists.
             
            if height == 1 {
                
                // there is only one value for height, and it going to be initial value
                
            } else {
                
                // there is height to be filled
                
                var heightLine: [Int] = []
                
                // cycle to fill height values
                
                var iterationAddition = 0
                
                for index in 1...(height - 1) { // was one
                    iterationAddition = iterationAddition - 1
                    heightLine.append(initialCoordinateValue + iterationAddition)
                }
                
                coordinateLine.append(contentsOf: heightLine)
            }
            
            if width == 1 {
                
                // there are no width lines to be filled
                // end of function
                
            } else if width - 1 == 1 {
                
                // there are things in width that we can add, for each width - 1 iterate over list and add stuff
                
                var columnList: [Int] = []
                
                for item in coordinateLine { // for each height create a list
                    cycleValue = item + resolution
                    columnList.append(cycleValue) // here is where multiplication by Resolution should go
                }

                coordinateLine.append(contentsOf: columnList)
                
            } else {

                // there are multiple lines to fill things in width that we can add, for each width - 1 iterate over list and add stuff
                
                var columnList: [Int] = []
                
                
                
                for column in 1...(width - 1) { // if 2 things to fill, it will be 1 additional step sequence
                    // for each column append values from the list but add Resolution * width to them
                    for item in coordinateLine { // for each height create a list
                        cycleValue = item + (resolution * column)
                        columnList.append(cycleValue) // here is where multiplication by Resolution should go
                    }
                    
                }

                coordinateLine.append(contentsOf: columnList)
                
            }
           
            */
            
            
            outputValuesList = oneBigValuesList
            outuupIndexList = coordinateLine

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
        
        // Create an empty list that will represent pixel values in Double.
        
        var gradientPixelArray: [Double] = []

        // Create a list with each pixel for a tile written as 0.
        
        for _ in 0...((resolution * resolution) - 1) {
            gradientPixelArray.append(0.0)
        }
        

        var cycleIndex = 0
        
        // For each value in gradient index list, replace index value with a gradient pixel value.
        
        for indexValue in gradientTestIndexList {
            gradientPixelArray[indexValue] = gradientTestValuesList[cycleIndex]
            cycleIndex = cycleIndex + 1
        }
        
        // Create an empty UInt32 list, that will be used to fill with actual color value.
        
        var pixelGrid: [UInt32] = []
        
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
        
        return pixelGrid
    }

    // This one is being used to convert Globe coordinates to Mercator coordinates on a square grid.
    
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
    
    // not being implemented now
    
    func rotateList(inputImage: [IndividualAuroraSpot]) -> [IndividualAuroraSpot] { // for now ill rotate everythong here and later will optimize it
        var outputImage: [IndividualAuroraSpot] = []
        
        // rotating image means flip 90 to the right.
       
        // sides are different len so i need to account for this
        
        let sideLen = 360
        let height = 171
        
        var rowList: [IndividualAuroraSpot] = []
        var itemIndex = 0
        
        // each side is equals to amount of elements i have per row, and index for next row position
        
        for column in 0...(Int(sideLen) - 1) {
            // cycle through each side, creating a row
            // secont loop will come here
            
            for _ in 0...(Int(height) - 1) {
                // collect items per each row
                rowList.append(inputImage[itemIndex])
                itemIndex = itemIndex + Int(sideLen) // goes to next line
                
            }

            itemIndex = 1 + column
            outputImage.append(contentsOf: rowList)
            
            rowList = []
    
        }
        return outputImage
    }
    
    // not being implemented now
    //  This method is for looking up a tile number with zoom level
    // I would need to create similar but that would return 2 lat and 2 lon values.
    
    func tranformCoordinate(_ latitude: Double, _ longitude: Double, withZoom zoom: Int) -> (x: Int, y: Int) {
        let tileX = Int(floor((longitude + 180) / 360.0 * pow(2.0, Double(zoom))))
        let tileY = Int(floor((1 - log( tan( latitude * Double.pi / 180.0 ) + 1 / cos( latitude * Double.pi / 180.0 )) / Double.pi ) / 2 * pow(2.0, Double(zoom))))
        
        return (tileX, tileY)
    }
    


    
    func fetchAurora() async {
        do {
            
//            Actual Data from Database online
            
//            try await provider.fetchAurora()
//            newList = provider.aurora.coordinates
            
//             Sample Data
            
            let downloader = TestDownloader()
            let client = AuroraClient(downloader: downloader)
            let aurora = try await client.aurora
            newList = aurora.coordinates
            //newPublicList = newList
            
            // save it to a local file?
            
            
            
            // For now resultion is declared here. will be automated later.
            
            newColorList = convertIncomingData(inputList: newList, resolution: 512)
            
        } catch {
            self.error = error as? AuroraError ?? .unexpectedError(error: error)
            self.hasError = true
        }
    }
}



