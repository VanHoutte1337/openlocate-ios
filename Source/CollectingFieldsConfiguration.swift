//
//  CollectingFieldsConfiguration.swift
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

/// Describes which data is sending from the device
public struct CollectingFieldsConfiguration {
    /// Determines whether network information is sending or not. Default value is true.
    public let shouldLogNetworkInfo: Bool

    /// Determines whether device course (bearing) is sending or not. Default value is true.
    public let shouldLogDeviceCourse: Bool

    /// Determines whether device speed is sending or not. Default value is true.
    public let shouldLogDeviceSpeed: Bool

    /// Determines whether device charging status should be sent ot not. Default value is true.
    public let shouldLogDeviceCharging: Bool

    /// Determines whether device model should be sent. Default value is true.
    public let shouldLogDeviceModel: Bool

    /// Determines whether device's os version is sent. Default value is true.
    public let shouldLogDeviceOsVersion: Bool

    /// Determines whether device's location coordinates will be sent. Default value is true.
    public let shouldLogLocation: Bool

    /// Determines whether timestamp of the recorded location in epoch will be sent. Default value is true.
    public let shouldLogTimestamp: Bool

    /// Determines whether accuracy of the location will be sent. Default value is true.
    public let shouldLogHorizontalAccuracy: Bool

    /// Determines whether altitude accuracy will be sent. Default value is true.
    public let shouldLogVerticalAccuracy: Bool

    /// Determines whether altitude will be sent. Default value is true.
    public let shouldLogAltitude: Bool

    /// Determines whether 'idfa' for identifying Apple device advertising type will be sent. Default value is true.
    public let shouldLogAdId: Bool
    
    /// Determines whether motion should be sent. Default value is true.
    public let shouldLogMotion: Bool

    /// Default configuration. All parameters are set to true.
    public static let `default` = CollectingFieldsConfiguration(
        shouldLogNetworkInfo: true,
        shouldLogDeviceCourse: true,
        shouldLogDeviceSpeed: true,
        shouldLogDeviceCharging: true,
        shouldLogDeviceModel: true,
        shouldLogDeviceOsVersion: true,
        shouldLogLocation: true,
        shouldLogTimestamp: true,
        shouldLogHorizontalAccuracy: true,
        shouldLogVerticalAccuracy: true,
        shouldLogAltitude: true,
        shouldLogAdId: true,
        shouldLogMotion: true
    )
}
