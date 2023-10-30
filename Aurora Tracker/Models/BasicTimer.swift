//
//  BasicTimer.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 7/18/23.
//

import Foundation

/*
    Sole reason is this function exist is so I can measure performance of my code
 
        later add an ability to create a file to log everything there, or store locally and print after certain action.
 */

class BasicTimer {
    
    let clock = ContinuousClock()
    
    func startTimer() -> DispatchTime {
        return DispatchTime.now()
    }
    
    func endTimer(_ start: DispatchTime, functionName: String) {
        let end = DispatchTime.now()
        
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        
        print("Time elapsed for function \(functionName) is \(timeInterval)")
    }
    
    func startCC() -> ContinuousClock.Instant {
        return clock.now
    }
    
    func endCC(_ start: ContinuousClock.Instant) {
        let nanoTime = clock.now - start
        print(nanoTime)
    }
}
