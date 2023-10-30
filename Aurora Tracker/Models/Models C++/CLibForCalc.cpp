//
//  CLibForCalc.cpp
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 7/20/23.
//

#include "CLibForCalc.hpp"

using namespace std;

class CLib {
    public:
    void myFunction() {
        cout << "Hello World" << endl;
    }
    
    int simpleCalculation(int inputNum) {
        int output {};
        output = inputNum * inputNum;
        return output;
    }
    
    /*
     
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
     
     */
    
    // rotates image 90 degrees to the right. First ever Function by me on C++!
    
    vector<int> rotateImage(vector<int> inputVector) {
            vector<int> outputImage {};
            
            double listLen = inputVector.size();
            int sideLen = sqrt(listLen);
            
            vector<int> rowList {};
            int itemIndex {};
            
            int column {};
            
            for (int i = 0; i < sideLen; i++) {
                
                for (int i = 0; i < sideLen; i++) {
                    rowList.push_back(inputVector[itemIndex]);
                    itemIndex = itemIndex + sideLen;
                }
                
                column = i;
                
                itemIndex = 1 + column;

                reverse(rowList.begin(), rowList.end());
                
                outputImage.insert(outputImage.end(), rowList.begin(), rowList.end());
                
                rowList = {};
            }
            
            return outputImage;
        }
    
    
    
    /*
     LATITUDE CALC
     
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
     
     
     */
    
    // multiple outputs?
    
    // this seems to be a working method, will test later
    
    struct mercatorSecondsCoordinates {
        double mercatorSecondLatitude;
        double mercatorSecondLongitude;
        
    };
    
    mercatorSecondsCoordinates latLonToMercatonSecond(double inputLatitude, double inputLongitude, int resolution) {
        
        mercatorSecondsCoordinates outputCoordinates;
        
        double mapSide = double(resolution);
        
        double outputLongitude = inputLongitude * (mapSide / 360.0);
        
        double latRad = inputLatitude * M_PI / 180;
        
        double mercN = log(tan((M_PI / 4) + (latRad / 2)));
        double outputLatitude = (mapSide / 2) - (mapSide * mercN / (2 / M_PI));
        
        // clarify rounding procedure later
        
        double roundedLatitude = round(outputLatitude);
        double roundedLongitude = round(outputLongitude);
        
        outputCoordinates.mercatorSecondLatitude = roundedLatitude;
        outputCoordinates.mercatorSecondLongitude = roundedLongitude;
        
        return outputCoordinates;
        
    };
    
    
    /*
     
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
     
     */
    
    // seems to be a simple decent solution that might just be working
    
    vector<double> tileToCoorinate( int tileX, int tileY, int zoom) {
        
        vector<double> outputList = {};
        
        double resolution = pow(2, double(zoom));
        
        double bottomLeftLat = atan(sinh(M_PI - (double(tileY) / resolution) * 2 * M_PI)) * (180.0 / M_PI);
        double bottomLeftLon = (double(tileX) / resolution) * 360.0;
        double bottomRightLon = (double(tileX + 1) / resolution) * 360.0;
        double topLeftLat = atan(sinh(M_PI - (double(tileY + 1) / resolution) * 2 * M_PI)) * (180.0 / M_PI);
        
        outputList.push_back(bottomLeftLat);
        outputList.push_back(bottomLeftLon);
        outputList.push_back(bottomRightLon);
        outputList.push_back(topLeftLat);
        
        return outputList;
    }
    
    
    
    
};

