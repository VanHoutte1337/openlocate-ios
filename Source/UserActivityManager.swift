//
//  UserActivityManager.swift
//  OpenLocate
//
//  Created by Mathias Van Houtte on 13/06/2018.
//  Copyright © 2018 OpenLocate. All rights reserved.
//

import UIKit
import CoreMotion

public protocol UserActivityProtocol {
    func start()
    func stop()
    
    func fetchUserActivity() -> UserCollectingFields?
}

class UserActivityManager: UserActivityProtocol {
    private let manager: CMMotionActivityManager
    private var currentMotionActivity: UserCollectingFields?
    
    init(manager: CMMotionActivityManager = CMMotionActivityManager()) {
        self.manager = manager
    }
    
    func start() {
        manager.startActivityUpdates(to: OperationQueue.main, withHandler: handleActivity)
    }
    
    func stop() {
        manager.stopActivityUpdates()
        
    }
    
    func fetchUserActivity() -> UserCollectingFields? {
        return currentMotionActivity
    }
    
    private func handleActivity(activity: CMMotionActivity?) {
        guard let activity = activity else {
            return
        }
        
        DispatchQueue.main.async {
            var activityType = "UNKNOWN";
            switch(activity) {
                case _ where activity.walking:
                    activityType = "WALKING"
                    break
                case _ where activity.stationary:
                    activityType = "STILL"
                    break
                case _ where activity.running:
                    activityType = "RUNNING"
                    break
                case _ where activity.automotive:
                    activityType = "VEHICLE"
                    break
                case _ where activity.cycling:
                    activityType = "BICYCLE"
                    break;
                
                default: break;
            }
            
            var confidence = 0
            switch(activity.confidence) {
            case .low:
                confidence = 50
                break
            case .medium:
                confidence = 50
                break
            case .high:
                confidence = 100
                break
            }
            
            self.currentMotionActivity = UserCollectingFields(userActivityType: activityType, userActivityConfidence: confidence)
        }
    }
}
