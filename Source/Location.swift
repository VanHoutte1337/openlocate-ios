//
//  Location.swift
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

/// JsonParameterType defines a protocol with getter for json

protocol JsonParameterType {
    var json: Parameters { get }
}

/// DataType defines a protocol to convert struct to data

protocol DataType {
    var data: Data { get }
}

// MARK: - Location

public struct OpenLocateLocation: JsonParameterType, DataType {

    private struct Keys {
        static let privateTimestamp = "private_utc_timestamp"
        static let adId = "ad_id"
        static let adOptOut = "ad_opt_out"
        static let adType = "id_type"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let timeStamp = "utc_timestamp"
        static let timestampReceived = "utc_timestamp_received"
        static let horizontalAccuracy = "horizontal_accuracy"
        static let verticalAccuracy = "vertical_accuracy"
        static let altitude = "altitude"
        static let wifiBssid = "wifi_bssid"
        static let wifissid = "wifi_ssid"
        static let carrierName = "carrier_name"
        static let locationContext = "location_context"
        static let course = "course"
        static let speed = "speed"
        static let isCharging = "is_charging"
        static let deviceModel = "device_model"
        static let osVersion = "os_version"
    }

    public enum Context: String {
        case unknown = "unknown"
        case passive = "passive"
        case regular = "regular"
        case visitEntry = "visit_entry"
        case visitExit = "visit_exit"
        case geofenceEntry = "geofence_entry"
        case geofenceExit = "geofence_exit"
        case backgroundFetch = "background_fetch"
    }

    private let idTypeValue = "idfa"

    // Save timestamp because it needs for detecting how much time did went since the first saved location.
    public let timestamp: Date
    public let advertisingInfo: AdvertisingInfo
    public let networkInfo: NetworkInfo
    public let locationFields: LocationCollectingFields
    public let deviceInfo: DeviceCollectingFields
    public let context: Context
    public let timestampReceived: Date?
    var createdAt: Date?

    var debugDescription: String {
        return "OpenLocateLocation(location: \(locationFields), advertisingInfo: \(advertisingInfo))"
    }

    init(timestamp: Date,
         advertisingInfo: AdvertisingInfo,
         collectingFields: CollectingFields,
         context: Context = .unknown) {

        self.timestampReceived = Date()
        self.timestamp = timestamp
        self.advertisingInfo = advertisingInfo
        self.networkInfo = collectingFields.networkInfo
        self.locationFields = collectingFields.locationFields
        self.deviceInfo = collectingFields.deviceInfo
        self.context = context
    }
}

extension OpenLocateLocation {
    var json: Parameters {
        var jsonParameters: [String: Any] = [Keys.adType: idTypeValue,
                                             Keys.locationContext: context.rawValue]

        if let advertisingInfo = advertisingInfo.advertisingId?.lowercased() {
            jsonParameters[Keys.adId] = advertisingInfo
        }

        if let advertisingInfo = advertisingInfo.isLimitedAdTrackingEnabled {
            jsonParameters[Keys.adOptOut] = advertisingInfo
        }

        if let latitude = locationFields.coordinates?.latitude {
            jsonParameters[Keys.latitude] = latitude
        }

        if let longitude = locationFields.coordinates?.longitude {
            jsonParameters[Keys.longitude] = longitude
        }

        if let timestamp = locationFields.timestamp?.timeIntervalSince1970 {
            jsonParameters[Keys.timeStamp] = Int(timestamp)
        }

        if let timestampReceived = timestampReceived?.timeIntervalSince1970 {
            jsonParameters[Keys.timestampReceived] = Int(timestampReceived)
        }

        if let horizontalAccuracy = locationFields.horizontalAccuracy {
            jsonParameters[Keys.horizontalAccuracy] = horizontalAccuracy
        }

        if let bssid = networkInfo.bssid {
            jsonParameters[Keys.wifiBssid] = bssid
        }

        if let wifissid = networkInfo.ssid {
            jsonParameters[Keys.wifissid] = wifissid
        }

        if let carrierName = networkInfo.carrierName {
            jsonParameters[Keys.carrierName] = carrierName
        }

        if let course = locationFields.course {
            jsonParameters[Keys.course] = course
        }

        if let speed = locationFields.speed {
            jsonParameters[Keys.speed] = speed
        }

        if let isCharging = deviceInfo.isCharging {
            jsonParameters[Keys.isCharging] = isCharging
        }

        if let deviceModel = deviceInfo.deviceModel {
            jsonParameters[Keys.deviceModel] = deviceModel
        }

        if let osVersion = deviceInfo.osVersion {
            jsonParameters[Keys.osVersion] = osVersion
        }

        return jsonParameters
    }
}

extension OpenLocateLocation {
    init(data: Data, createdAt: Date) throws {
        guard let coding = NSKeyedUnarchiver.unarchiveObject(with: data) as? Coding else {
            throw OpenLocateLocationError.unarchivingCannotBeDone
        }

        self.advertisingInfo = AdvertisingInfo.Builder()
            .set(advertisingId: coding.advertisingId)
            .set(isLimitedAdTrackingEnabled: coding.isLimitedAdTrackingEnabled)
            .build()

        self.networkInfo = NetworkInfo(bssid: coding.bssid, ssid: coding.ssid, carrierName: coding.carrierName)

        var coordinates: CLLocationCoordinate2D?
        if let latitude = coding.latitude, let longitude = coding.longitude {
            coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        }

        var timestamp: Date?
        if let timeIntervalTimestamp = coding.timestamp {
            timestamp = Date(timeIntervalSince1970: timeIntervalTimestamp)
            self.timestamp = timestamp!
        } else {
            self.timestamp = Date(timeIntervalSince1970: coding.privateTimestamp)
        }

        self.locationFields = LocationCollectingFields(course: coding.course,
                                                       speed: coding.speed,
                                                       coordinates: coordinates,
                                                       timestamp: timestamp,
                                                       horizontalAccuracy: coding.horizontalAccuracy,
                                                       verticalAccuracy: coding.verticalAccuracy,
                                                       altitude: coding.altitude)

        self.deviceInfo = DeviceCollectingFields(isCharging: coding.isCharging,
                                                 deviceModel: coding.deviceModel,
                                                 osVersion: coding.osVersion)

        if let contextString = coding.context, let context = Context(rawValue: contextString) {
            self.context = context
        } else {
            self.context = .unknown
        }

        if let timeIntervalTimestampReceived = coding.timestampReceived {
            self.timestampReceived = Date(timeIntervalSince1970: timeIntervalTimestampReceived)
        } else {
            self.timestampReceived = nil
        }

        self.createdAt = createdAt
    }

    var data: Data {
        return NSKeyedArchiver.archivedData(withRootObject: Coding(self))
    }

    @objc(OL) private class Coding: NSObject, NSCoding {
        let privateTimestamp: TimeInterval

        let latitude: CLLocationDegrees?
        let longitude: CLLocationDegrees?
        let timestamp: TimeInterval?
        let timestampReceived: TimeInterval?
        let horizontalAccuracy: CLLocationAccuracy?
        let verticalAccuracy: CLLocationAccuracy?
        let altitude: CLLocationDistance?
        let advertisingId: String?
        let isLimitedAdTrackingEnabled: Bool?
        let bssid: String?
        let ssid: String?
        let carrierName: String?
        let context: String?
        let course: Double?
        let speed: Double?
        let isCharging: Bool?
        let deviceModel: String?
        let osVersion: String?

        init(_ location: OpenLocateLocation) {
            privateTimestamp = location.timestamp.timeIntervalSince1970
            latitude = location.locationFields.coordinates?.latitude
            longitude = location.locationFields.coordinates?.longitude
            timestamp = location.locationFields.timestamp?.timeIntervalSince1970
            timestampReceived = location.timestampReceived?.timeIntervalSince1970
            horizontalAccuracy = location.locationFields.horizontalAccuracy
            verticalAccuracy = location.locationFields.verticalAccuracy
            altitude = location.locationFields.altitude
            advertisingId = location.advertisingInfo.advertisingId
            isLimitedAdTrackingEnabled = location.advertisingInfo.isLimitedAdTrackingEnabled
            bssid = location.networkInfo.bssid
            ssid = location.networkInfo.ssid
            carrierName = location.networkInfo.carrierName
            context = location.context.rawValue
            course = location.locationFields.course
            speed = location.locationFields.speed
            isCharging = location.deviceInfo.isCharging
            deviceModel = location.deviceInfo.deviceModel
            osVersion = location.deviceInfo.osVersion

            super.init()
        }

        required init?(coder decoder: NSCoder) {
            privateTimestamp = decoder.decodeDouble(forKey: OpenLocateLocation.Keys.privateTimestamp)
            latitude = decoder.decodeObject(forKey: OpenLocateLocation.Keys.latitude) as? CLLocationDegrees
            longitude = decoder.decodeObject(forKey: OpenLocateLocation.Keys.longitude) as? CLLocationDegrees
            timestamp = decoder.decodeObject(forKey: OpenLocateLocation.Keys.timeStamp) as? TimeInterval
            timestampReceived = decoder.decodeObject(forKey: OpenLocateLocation.Keys.timestampReceived) as? TimeInterval
            altitude = decoder.decodeObject(forKey: OpenLocateLocation.Keys.altitude) as? CLLocationDistance
            advertisingId = decoder.decodeObject(forKey: OpenLocateLocation.Keys.adId) as? String
            isLimitedAdTrackingEnabled = decoder.decodeObject(forKey: OpenLocateLocation.Keys.adOptOut) as? Bool
            bssid = decoder.decodeObject(forKey: OpenLocateLocation.Keys.wifiBssid) as? String
            ssid = decoder.decodeObject(forKey: OpenLocateLocation.Keys.wifissid) as? String
            carrierName = decoder.decodeObject(forKey: OpenLocateLocation.Keys.carrierName) as? String
            context = decoder.decodeObject(forKey: OpenLocateLocation.Keys.locationContext) as? String
            course = decoder.decodeObject(forKey: OpenLocateLocation.Keys.course) as? Double
            speed = decoder.decodeObject(forKey: OpenLocateLocation.Keys.speed) as? Double
            isCharging = decoder.decodeObject(forKey: OpenLocateLocation.Keys.isCharging) as? Bool
            deviceModel = decoder.decodeObject(forKey: OpenLocateLocation.Keys.deviceModel) as? String
            osVersion = decoder.decodeObject(forKey: OpenLocateLocation.Keys.osVersion) as? String
            horizontalAccuracy
                = decoder.decodeObject(forKey: OpenLocateLocation.Keys.horizontalAccuracy) as? CLLocationAccuracy
            verticalAccuracy
                = decoder.decodeObject(forKey: OpenLocateLocation.Keys.verticalAccuracy) as? CLLocationAccuracy

            super.init()
        }

        func encode(with aCoder: NSCoder) {
            aCoder.encode(privateTimestamp, forKey: OpenLocateLocation.Keys.privateTimestamp)
            aCoder.encode(latitude, forKey: OpenLocateLocation.Keys.latitude)
            aCoder.encode(longitude, forKey: OpenLocateLocation.Keys.longitude)
            aCoder.encode(timestamp, forKey: OpenLocateLocation.Keys.timeStamp)
            aCoder.encode(timestampReceived, forKey: OpenLocateLocation.Keys.timestampReceived)
            aCoder.encode(altitude, forKey: OpenLocateLocation.Keys.altitude)
            aCoder.encode(advertisingId, forKey: OpenLocateLocation.Keys.adId)
            aCoder.encode(isLimitedAdTrackingEnabled, forKey: OpenLocateLocation.Keys.adOptOut)
            aCoder.encode(bssid, forKey: OpenLocateLocation.Keys.wifiBssid)
            aCoder.encode(ssid, forKey: OpenLocateLocation.Keys.wifissid)
            aCoder.encode(carrierName, forKey: OpenLocateLocation.Keys.carrierName)
            aCoder.encode(context, forKey: OpenLocateLocation.Keys.locationContext)
            aCoder.encode(course, forKey: OpenLocateLocation.Keys.course)
            aCoder.encode(speed, forKey: OpenLocateLocation.Keys.speed)
            aCoder.encode(isCharging, forKey: OpenLocateLocation.Keys.isCharging)
            aCoder.encode(deviceModel, forKey: OpenLocateLocation.Keys.deviceModel)
            aCoder.encode(osVersion, forKey: OpenLocateLocation.Keys.osVersion)
            aCoder.encode(horizontalAccuracy, forKey: OpenLocateLocation.Keys.horizontalAccuracy)
            aCoder.encode(verticalAccuracy, forKey: OpenLocateLocation.Keys.verticalAccuracy)
        }
    }
}
