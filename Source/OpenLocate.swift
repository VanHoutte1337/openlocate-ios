//
//  OpenLocate.swift
//
//  Copyright (c) 2017 OpenLocate
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import AdSupport

public typealias LocationCompletionHandler = (OpenLocateLocation?, Error?) -> Void

protocol OpenLocateType {
    static var shared: OpenLocate { get }
    
    var locationService: LocationServiceType? {get set}
    var isTrackingEnabled: Bool { get }
    
    func initialize(with configuration: Configuration) throws
    
    func startTracking()
    func stopTracking()
    
    func sendData(onCompletion: @escaping (Bool) -> Void)
    
    func fetchCurrentLocation(completion: LocationCompletionHandler) throws
    
    func getJSON(_ location: OpenLocateLocation) -> Any
    
    func getLogging() -> String
    func clearLogging()
    func getExportPath() -> URL
}

public class OpenLocate: OpenLocateType {
    
    public var locationService: LocationServiceType?
    var userActivityManager: UserActivityManager?
    
    fileprivate var configuration: Configuration?
    
    public static let shared = OpenLocate()
}

extension OpenLocate {
    private func initLocationService(configuration: Configuration) {
        LoggingService.shared.log("initLocationService: interval: \(configuration.transmissionInterval)")
        let httpClient = HttpClient()
        
        let locationDataSource: LocationDataSourceType
        
        do {
            let database = try SQLiteDatabase.openLocateDatabase()
            locationDataSource = LocationDatabase(database: database)
        } catch {
            locationDataSource = LocationList()
        }
        
        let locationManager = LocationManager(requestAuthorizationStatus: configuration.authorizationStatus)
        
        let userActivityManager =  UserActivityManager()
        
        self.configuration = configuration
        
        self.locationService = LocationService(
            postable: httpClient,
            locationDataSource: locationDataSource,
            endpoints: configuration.endpoints,
            advertisingInfo: advertisingInfo,
            locationManager: locationManager,
            transmissionInterval: configuration.transmissionInterval,
            logConfiguration: configuration.collectingFieldsConfiguration,
            userActivityManager: userActivityManager
        )
        
        if let locationService = self.locationService, locationService.isStarted {
            locationService.start()
        }
    }
    
    public func initialize(with configuration: Configuration) throws {
        try validateLocationAuthorizationKeys()
        
        initLocationService(configuration: configuration)
    }
    
    public func startTracking() {
        locationService?.start()
    }
    
    public func stopTracking() {
        guard let service = locationService else {
            debugPrint("Trying to stop server even if it was never started.")
            LoggingService.shared.log("Trying to stop server even if it was never started.")
            
            return
        }
        
        service.stop()
    }
    
    public func getJSON(_ location: OpenLocateLocation) -> Any {
        return location.json
    }
    
    public func getLogging() -> String {
        return LoggingService.shared.getLogs()
    }
    
    public func clearLogging() {
        LoggingService.shared.clear()
    }
    
    public func getExportPath() -> URL {
        return LoggingService.shared.getExportPath()
    }
    
    public var isTrackingEnabled: Bool {
        guard let locationService = self.locationService else { return false }
        
        return locationService.isStarted
    }
    
    public func performFetchWithCompletionHandler(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        LoggingService.shared.log("Background fetch initiated")
        guard let locationService = self.locationService, locationService.isStarted else {
            LoggingService.shared.log("Background fetch: No data")
            completionHandler(.noData)
            return
        }
        
        locationService.backgroundFetchLocation { (success) in
            if success {
                LoggingService.shared.log("Background fetch: New data")
                completionHandler(.newData)
            } else {
                LoggingService.shared.log("Background fetch: No data")
                completionHandler(.noData)
            }
        }
    }
    
    private var advertisingInfo: AdvertisingInfo {
        let manager = ASIdentifierManager.shared()
        
        var advertisingId: String?
        var isLimitedAdTrackingEnabled: Bool?
        
        if let shouldLogAdId = configuration?.collectingFieldsConfiguration.shouldLogAdId, shouldLogAdId {
            advertisingId = manager.advertisingIdentifier.uuidString
            isLimitedAdTrackingEnabled = !manager.isAdvertisingTrackingEnabled
        }
        
        let advertisingInfo = AdvertisingInfo.Builder()
            .set(advertisingId: advertisingId)
            .set(isLimitedAdTrackingEnabled: isLimitedAdTrackingEnabled)
            .build()
        
        return advertisingInfo
    }
    
    public func sendData(onCompletion: @escaping (Bool) -> Void) {
        if let locationService = self.locationService {
            locationService.postData(onComplete: { (isSuccessfull) in
                onCompletion(isSuccessfull)
            })
        } else {
            onCompletion(false)
        }
    }
}

extension OpenLocate {
    public func fetchCurrentLocation(completion: (OpenLocateLocation?, Error?) -> Void) throws {
        try validateLocationAuthorizationKeys()
        
        let manager = LocationManager(requestAuthorizationStatus: .authorizedWhenInUse)
        let lastLocation = manager.lastLocation
        
        guard let location = lastLocation else {
            completion(
                nil,
                OpenLocateError.locationFailure(message: OpenLocateError.ErrorMessage.noCurrentLocationExists))
            return
        }
        
        let fieldsConfiguration = configuration?.collectingFieldsConfiguration ?? .default
        
        let fieldsContainer = CollectingFields.Builder(configuration: fieldsConfiguration)
            .set(location: location)
            .set(network: NetworkInfo.currentNetworkInfo())
            .set(deviceInfo: DeviceCollectingFields.configure(with: fieldsConfiguration))
            .build()
        
        let openlocateLocation = OpenLocateLocation(timestamp: location.timestamp,
                                                    advertisingInfo: advertisingInfo,
                                                    collectingFields: fieldsContainer)
        completion(openlocateLocation, nil)
    }
}

extension OpenLocate {
    private func validateLocationAuthorizationKeys() throws {
        if !LocationService.isAuthorizationKeysValid() {
            debugPrint(OpenLocateError.ErrorMessage.missingAuthorizationKeysMessage)
            LoggingService.shared.log(OpenLocateError.ErrorMessage.missingAuthorizationKeysMessage)
            throw OpenLocateError.locationMissingAuthorizationKeys(
                message: OpenLocateError.ErrorMessage.missingAuthorizationKeysMessage
            )
        }
    }
}
