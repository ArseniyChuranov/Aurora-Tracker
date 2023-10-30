//
//  File.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 9/26/23.
//

import Foundation
import UIKit
import BackgroundTasks

class BackgroundAuroraRefreshRequester: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // requestor?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // submitBackgroundTasks()
        registerBackgroundTasks()
        
        return true
    }
    
    func registerBackgroundTasks() {
        let backgroundAppRefreshTaskSchedulerIdentifier = "com.arseniychuranov.auroraFetchNewDataIdentifier"
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshTaskSchedulerIdentifier, using: nil) {(task) in
            print("background is starting now")
            task.expirationHandler = {
                task.setTaskCompleted(success: false)
            }
            
            let isFetchingSuccess = true
            task.setTaskCompleted(success: isFetchingSuccess)
        }
        
        
    }
    
    
    
    
    /*
    func submitBackgroundTasks() {
        // figure things here slowly and find a way to fetch data once per day,
        // and maybe even have a schedule based on preference
        
        let backgroundAppRefreshTaskSchedulerIdentifier = "com.arseniychuranov.auroraFetchNewDataIdentifier"
        let timeDelay = 10.0
        
        do {
            let backgroundAppRefreshTastRequest = BGAppRefreshTaskRequest()
            
        } catch {
            
        }
        
    }
     
     */
}
