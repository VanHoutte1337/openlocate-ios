//
//  LocationService.swift
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
import CoreLocation

protocol LocationServiceType {
    var transmissionInterval: TimeInterval { get set }

    var isStarted: Bool { get }

    func start()
    func stop()

    func postData(onComplete: ((Bool) -> Void)?)

    func backgroundFetchLocation(onCompletion: @escaping ((Bool) -> Void))
}

private let locationsKey = "locations"

final class LocationService: LocationServiceType {

    let isStartedKey = "OpenLocate_isStarted"
    let endpointsInfoKey = "OpenLocate_EndpointsInfo"
    let endpointLastTransmitDate = "lastTransmitDate"
    let maxNumberOfDaysStored = 10
    let maxForegroundLocationUpdateInterval: TimeInterval = 15 * 60.0 // 15 minutes

    let collectingFieldsConfiguration: CollectingFieldsConfiguration

    var transmissionInterval: TimeInterval

    var isStarted: Bool {
        return UserDefaults.standard.bool(forKey: isStartedKey)
    }

    private let locationManager: LocationManagerType
    private let httpClient: Postable
    private let locationDataSource: LocationDataSourceType
    private var advertisingInfo: AdvertisingInfo
    private let executionQueue: DispatchQueue = DispatchQueue(label: "openlocate.queue.async", qos: .background)

    private let endpoints: [Configuration.Endpoint]
    private var isPostingLocations = false
    private var lastTransmissionDate: Date?
    private var endpointsInfo: [String: [String: Any]]

    private let dispatchGroup = DispatchGroup()
    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

    init(
        postable: Postable,
        locationDataSource: LocationDataSourceType,
        endpoints: [Configuration.Endpoint],
        advertisingInfo: AdvertisingInfo,
        locationManager: LocationManagerType,
        transmissionInterval: TimeInterval,
        logConfiguration: CollectingFieldsConfiguration) {

        httpClient = postable
        self.locationDataSource = locationDataSource
        self.locationManager = locationManager
        self.advertisingInfo = advertisingInfo
        self.endpoints = endpoints
        self.transmissionInterval = transmissionInterval
        self.collectingFieldsConfiguration = logConfiguration

        if let endpointsInfo = UserDefaults.standard.dictionary(forKey: endpointsInfoKey) as? [String: [String: Any]] {
            self.endpointsInfo = endpointsInfo
        } else {
            self.endpointsInfo = [String: [String: Any]]()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        debugPrint("Location service started for urls : \(endpoints.map({$0.url}))")

        locationManager.subscribe { [weak self] locations in
            self?.addUpdatedLocations(locations: locations)
        }

        UserDefaults.standard.set(true, forKey: isStartedKey)
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive,
                                               object: nil)
    }

    // swiftlint:disable notification_center_detachment
    func stop() {
        locationManager.cancel()
        locationDataSource.clear()

        UserDefaults.standard.set(false, forKey: isStartedKey)
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        NotificationCenter.default.removeObserver(self)
    }

    func backgroundFetchLocation(onCompletion: @escaping ((Bool) -> Void)) {
        if let lastKnownLocation = locationManager.lastLocation {
            addUpdatedLocations(locations: [(location: lastKnownLocation, context: .passive)])
        }
        locationManager.fetchLocation(onCompletion: onCompletion)
    }

}

extension LocationService {

    private func addUpdatedLocations(locations: [(location: CLLocation, context: OpenLocateLocation.Context)]) {
        self.executionQueue.async { [weak self] in
            guard let strongSelf = self else { return }

            let collectingFields = DeviceCollectingFields.configure(with: strongSelf.collectingFieldsConfiguration)

            let openLocateLocations: [OpenLocateLocation] = locations.map {
                let info = CollectingFields.Builder(configuration: strongSelf.collectingFieldsConfiguration)
                    .set(location: $0.location)
                    .set(network: NetworkInfo.currentNetworkInfo())
                    .set(deviceInfo: collectingFields)
                    .build()

                return OpenLocateLocation(timestamp: $0.location.timestamp,
                                          advertisingInfo: strongSelf.advertisingInfo,
                                          collectingFields: info,
                                          context: $0.context)
            }

            strongSelf.locationDataSource.addAll(locations: openLocateLocations)

            //debugPrint(strongSelf.locationDataSource.all())

            strongSelf.postLocationsIfNeeded()
        }
    }

    func postLocationsIfNeeded() {
        if let earliestLocation = locationDataSource.first(), let createdAt = earliestLocation.createdAt,
            abs(createdAt.timeIntervalSinceNow) > self.transmissionInterval {

            if let lastTransmissionDate = self.lastTransmissionDate,
                lastTransmissionDate.timeIntervalSinceNow < self.transmissionInterval / 2 {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: { [weak self] in
                self?.postData()
            })
        }
    }

    func postData(onComplete: ((Bool) -> Void)? = nil) {

        if isPostingLocations == true || endpoints.isEmpty { return }

        isPostingLocations = true

        beginBackgroundTask()

        var isSuccessfull = true
        let endingDate = Calendar.current.date(byAdding: .second, value: -1, to: Date()) ?? Date()
        for endpoint in endpoints {
            dispatchGroup.enter()
            do {
                let date = lastKnownTransmissionDate(for: endpoint)
                let locations = locationDataSource.all(starting: date, ending: endingDate)

                let params = [locationsKey: locations.map { $0.json }]
                let requestParameters = URLRequestParamters(url: endpoint.url.absoluteString,
                                                            params: params,
                                                            queryParams: nil,
                                                            additionalHeaders: endpoint.headers)
                try httpClient.post(
                    parameters: requestParameters,
                    success: {  [weak self] _, _ in
                        if let lastLocation = locations.last, let createdAt = lastLocation.createdAt {
                            self?.setLastKnownTransmissionDate(for: endpoint, with: createdAt)
                        }
                        self?.dispatchGroup.leave()
                    },
                    failure: { [weak self] _, error in
                        debugPrint("failure in posting locations!!! Error: \(error)")
                        isSuccessfull = false
                        self?.dispatchGroup.leave()
                    }
                )
            } catch let error {
                print(error.localizedDescription)
                isSuccessfull = false
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.lastTransmissionDate = Date()
            strongSelf.locationDataSource.clear(before: strongSelf.transmissionDateCutoff())
            strongSelf.isPostingLocations = false
            strongSelf.endBackgroundTask()

            if let onComplete = onComplete {
                onComplete(isSuccessfull)
            }
        }
    }

    private func lastKnownTransmissionDate(for endpoint: Configuration.Endpoint) -> Date {
        let key = infoKeyForEndpoint(endpoint)
        if let endpointInfo = endpointsInfo[key],
            let date = endpointInfo[endpointLastTransmitDate] as? Date, date <= Date() {

            return date
        }
        return Date.distantPast
    }

    private func setLastKnownTransmissionDate(for endpoint: Configuration.Endpoint, with date: Date) {
        let key = infoKeyForEndpoint(endpoint)
        endpointsInfo[key] = [endpointLastTransmitDate: date]
        persistEndPointsInfo()
    }

    private func transmissionDateCutoff() -> Date {
        var cutoffDate = Date()
        for (_, endpointInfo) in endpointsInfo {
            if let date = endpointInfo[endpointLastTransmitDate] as? Date {
                if date < cutoffDate {
                    cutoffDate = date
                }
            } else {
                cutoffDate = Date.distantPast
            }
        }

        if let maxCutoffDate = Calendar.current.date(byAdding: .day, value: -maxNumberOfDaysStored, to: Date()),
            maxCutoffDate > cutoffDate {

            return maxCutoffDate
        }
        return cutoffDate
    }

    private func infoKeyForEndpoint(_ endpoint: Configuration.Endpoint) -> String {
        return endpoint.url.absoluteString.lowercased()
    }

    private func persistEndPointsInfo() {
        UserDefaults.standard.set(endpointsInfo, forKey: endpointsInfoKey)
        UserDefaults.standard.synchronize()
    }

    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }

    @objc private func applicationDidBecomeActive(notification: NSNotification) {
        if UIApplication.shared.applicationState == .active {
            if let lastKnownLocation = locationManager.lastLocation {
                addUpdatedLocations(locations: [(location: lastKnownLocation, context: .passive)])
                if abs(lastKnownLocation.timestamp.timeIntervalSinceNow) > maxForegroundLocationUpdateInterval {
                    locationManager.fetchLocation(onCompletion: { _ in })
                }
            }
        }
    }

    static func isAuthorizationKeysValid() -> Bool {
        let always = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription")
        let inUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription")
        let alwaysAndinUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription")

        if #available(iOS 11, *) {
            return always != nil && inUse != nil && alwaysAndinUse != nil
        }

        return always != nil
    }
}
