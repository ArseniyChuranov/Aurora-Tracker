//
//  simpleCalcLibr.cpp
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 9/28/23.
//

#include "simpleCalcLibr.hpp"

using namespace std;

/*

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

 */


double calculateLatitude(double inputCoordinate, int coordinateZoom) {
    double output = 0;
    
    double mapSide = double(coordinateZoom);
    
    double resolution = pow(2, mapSide);
    
    // maybe I was drunk when I made this?
    
    double newResolution = resolution * 255;
    
    resolution = 256 * resolution;
    
    double latRad = inputCoordinate * M_PI / 180;
    double mercN = log(tan((M_PI / 4) + (latRad / 2)));
    
    output = (resolution / 2) - (newResolution * mercN / (2 * M_PI));
    
    return output;
}


/*

 func calculateLongitude(inputLongitude: Double, coordinateZoom: Int) -> Double {
     
     let mapSide = Double(coordinateZoom)
     
     var resolution = Double(pow(2, mapSide))
     
     resolution = 255 * resolution // was 256
     
     let outputLongitude = inputLongitude * (resolution / 360)
     
     return outputLongitude
 }

*/

double calculateLongitude(double inputLongitude, int coordinateZoom) {
    double output = 0;
    
    double mapSide = double(coordinateZoom);
    
    double resolution = pow(2, mapSide);
    
    resolution = 255 * resolution;
    
    output = inputLongitude * (resolution / 360);
    
    return output;
}


/*
 
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
 
 */

double calculateIncrement(double inputFirstNum, double inputSecondNum, int distance) {
    
    double increment = (inputFirstNum - inputSecondNum) / double(distance);
    
    //failcheck
    
    if (isnan(increment) || isinf(increment)) {
        cout << increment << endl;
        cout << inputFirstNum << endl;
        cout << inputSecondNum << endl;
    }
    
    return increment;
    
}
