//
//  CollectingFields.swift
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

import CoreLocation.CLLocation

/// Contains all fields configurable with CollectingFieldsConfiguration
struct CollectingFields {
    let networkInfo: NetworkInfo
    let locationFields: LocationCollectingFields
    let deviceInfo: DeviceCollectingFields
    let userInfo: UserCollectingFields

    private init(networkInfo: NetworkInfo,
                 locationFields: LocationCollectingFields,
                 deviceInfo: DeviceCollectingFields,
                 userInfo: UserCollectingFields) {
        self.networkInfo = networkInfo
        self.locationFields = locationFields
        self.deviceInfo = deviceInfo
        self.userInfo = userInfo
    }
}

extension CollectingFields {
    final class Builder {
        let configuration: CollectingFieldsConfiguration

        private var location: CLLocation?
        private var deviceInfo: DeviceCollectingFields?
        private var networkInfo: NetworkInfo = .currentNetworkInfo()
        private var userInfo: UserCollectingFields?

        init(configuration: CollectingFieldsConfiguration) {
            self.configuration = configuration
        }

        func set(network: NetworkInfo) -> Builder {
            self.networkInfo = network

            return self
        }

        func set(location: CLLocation) -> Builder {
            self.location = location

            return self
        }

        func set(deviceInfo: DeviceCollectingFields) -> Builder {
            self.deviceInfo = deviceInfo

            return self
        }
        
        func set(userInfo: UserCollectingFields?) -> Builder {
            self.userInfo = userInfo
            
            return self
        }

        func build() -> CollectingFields {
            let networkInfo = configuration.shouldLogNetworkInfo ? self.networkInfo : NetworkInfo()

            let course = configuration.shouldLogDeviceCourse ? self.location?.course : nil
            let speed = configuration.shouldLogDeviceSpeed ? self.location?.speed : nil
            let coordinates = configuration.shouldLogLocation ? self.location?.coordinate : nil
            let timestamp = configuration.shouldLogTimestamp ? self.location?.timestamp : nil
            let horizontalAccuracy = configuration.shouldLogHorizontalAccuracy ? self.location?.horizontalAccuracy : nil
            let verticalAccuracy = configuration.shouldLogVerticalAccuracy ? self.location?.verticalAccuracy : nil
            let altitude = configuration.shouldLogAltitude ? self.location?.altitude : nil

            let deviceLocationInfo
                = LocationCollectingFields(course: course,
                                           speed: speed,
                                           coordinates: coordinates,
                                           timestamp: timestamp,
                                           horizontalAccuracy: horizontalAccuracy,
                                           verticalAccuracy: verticalAccuracy,
                                           altitude: altitude)

            let deviceInfo = self.deviceInfo ?? DeviceCollectingFields.configure(with: configuration)
            let userInfo = self.userInfo ?? UserCollectingFields()
            
            return CollectingFields(networkInfo: networkInfo,
                                    locationFields: deviceLocationInfo,
                                    deviceInfo: deviceInfo,
                                    userInfo: userInfo)
        }
    }
}
