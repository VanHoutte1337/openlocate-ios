//
//  CollectingFieldsConfigurationBuilder.swift
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

public extension CollectingFieldsConfiguration {
    final public class Builder {
        private var shouldLogNetworkInfo = true
        private var shouldLogDeviceCourse = true
        private var shouldLogDeviceSpeed = true
        private var shouldLogDeviceCharging = true
        private var shouldLogDeviceModel = true
        private var shouldLogDeviceOsVersion = true
        private var shouldLogLocation = true
        private var shouldLogTimestamp = true
        private var shouldLogHorizontalAccuracy = true
        private var shouldLogVerticalAccuracy = true
        private var shouldLogAltitude = true
        private var shouldLogAdId = true
        private var shouldLogMotion = true

        public init() {}

        public func set(shouldLogNetworkInfo: Bool) -> Builder {
            self.shouldLogNetworkInfo = shouldLogNetworkInfo

            return self
        }

        public func set(shouldLogDeviceCourse: Bool) -> Builder {
            self.shouldLogDeviceCourse = shouldLogDeviceCourse

            return self
        }

        public func set(shouldLogDeviceSpeed: Bool) -> Builder {
            self.shouldLogDeviceSpeed = shouldLogDeviceSpeed

            return self
        }

        public func set(shouldLogDeviceCharging: Bool) -> Builder {
            self.shouldLogDeviceCharging = shouldLogDeviceCharging

            return self
        }

        public func set(shouldLogDeviceModel: Bool) -> Builder {
            self.shouldLogDeviceModel = shouldLogDeviceModel

            return self
        }

        public func set(shouldLogDeviceOsVersion: Bool) -> Builder {
            self.shouldLogDeviceOsVersion = shouldLogDeviceOsVersion

            return self
        }

        public func set(shouldLogLocation: Bool) -> Builder {
            self.shouldLogLocation = shouldLogLocation

            return self
        }

        public func set(shouldLogTimestamp: Bool) -> Builder {
            self.shouldLogTimestamp = shouldLogTimestamp

            return self
        }

        public func set(shouldLogHorizontalAccuracy: Bool) -> Builder {
            self.shouldLogHorizontalAccuracy = shouldLogHorizontalAccuracy

            return self
        }

        public func set(shouldLogVerticalAccuracy: Bool) -> Builder {
            self.shouldLogVerticalAccuracy = shouldLogVerticalAccuracy

            return self
        }

        public func set(shouldLogAltitude: Bool) -> Builder {
            self.shouldLogAltitude = shouldLogAltitude

            return self
        }

        public func set(shouldLogIdType: Bool) -> Builder {
            self.shouldLogAdId = shouldLogIdType

            return self
        }
        
        public func set(shouldLogMotionType: Bool) -> Builder {
            self.shouldLogMotion = shouldLogMotionType
            
            return self
        }

        public func build() -> CollectingFieldsConfiguration {
            return CollectingFieldsConfiguration(shouldLogNetworkInfo: shouldLogNetworkInfo,
                                                 shouldLogDeviceCourse: shouldLogDeviceCourse,
                                                 shouldLogDeviceSpeed: shouldLogDeviceSpeed,
                                                 shouldLogDeviceCharging: shouldLogDeviceCharging,
                                                 shouldLogDeviceModel: shouldLogDeviceModel,
                                                 shouldLogDeviceOsVersion: shouldLogDeviceOsVersion,
                                                 shouldLogLocation: shouldLogLocation,
                                                 shouldLogTimestamp: shouldLogTimestamp,
                                                 shouldLogHorizontalAccuracy: shouldLogHorizontalAccuracy,
                                                 shouldLogVerticalAccuracy: shouldLogVerticalAccuracy,
                                                 shouldLogAltitude: shouldLogAltitude,
                                                 shouldLogAdId: shouldLogAdId,
                                                 shouldLogMotion:shouldLogMotion)
        }
    }
}
