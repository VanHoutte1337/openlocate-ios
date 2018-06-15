//
//  DataSourceTests.swift
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

import XCTest
@testable import OpenLocate
import CoreLocation

class LocationDataSourceTests: BaseTestCase {
    private var dataSource: LocationDataSourceType?

    var testLocation: OpenLocateLocation {
        let coreLocation = CLLocation(
            coordinate: CLLocationCoordinate2DMake(123.12, 123.123),
            altitude: 30.0,
            horizontalAccuracy: 10,
            verticalAccuracy: 0,
            course: 180,
            speed: 20,
            timestamp: Date(timeIntervalSince1970: 1234)
        )

        let advertisingInfo = AdvertisingInfo.Builder()
            .set(isLimitedAdTrackingEnabled: false)
            .set(advertisingId: "123")
            .build()

        let networkInfo = NetworkInfo(bssid: "bssid_goes_here", ssid: "ssid_goes_here", carrierName: "carrier_goes_here")
        let deviceInfo = DeviceCollectingFields(isCharging: false, deviceModel: "iPhone9,4", osVersion: "iOS 11.0.1")

        let info = CollectingFields.Builder(configuration: .default)
            .set(location: coreLocation)
            .set(network: networkInfo)
            .set(deviceInfo: deviceInfo)
            .build()

        return OpenLocateLocation(
            timestamp: coreLocation.timestamp,
            advertisingInfo: advertisingInfo,
            collectingFields: info
        )
    }

    override func setUp() {
        do {
            let database = try SQLiteDatabase.testDB()
            dataSource = LocationDatabase(database: database)
            _ = dataSource!.clear()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func testAddLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        do {
            try locations.add(location: testLocation)
        } catch let error {
            debugPrint(error.localizedDescription)
            XCTFail("Add Location error")
        }

        // Then
        XCTAssertEqual(locations.count, 1)
    }

    func testAddMultipleLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        // Then
        XCTAssertEqual(locations.count, 3)
    }

    func testPopAllLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)
        let popped = locations.all()
        locations.clear()

        // Then
        XCTAssertEqual(popped.count, 4)
        XCTAssertEqual(locations.count, 0)
    }

    func testFirstLocation() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)
        let firstIndexedLocation = locations.first()

        // Then
        do {
            let firstLocation = try OpenLocateLocation(data: firstIndexedLocation!.data,
                                                       createdAt: firstIndexedLocation!.createdAt!)
            XCTAssertEqual(firstLocation.locationFields.coordinates?.latitude,
                           testLocation.locationFields.coordinates?.latitude)
            XCTAssertEqual(firstLocation.locationFields.coordinates?.longitude,
                           testLocation.locationFields.coordinates?.longitude)
            XCTAssertEqual(firstLocation.locationFields.timestamp!.timeIntervalSince1970,
                           testLocation.locationFields.timestamp!.timeIntervalSince1970,
                           accuracy: 0.1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

class LocationListDataSource: BaseTestCase {
    private var dataSource: LocationDataSourceType?

    var testLocation: OpenLocateLocation {
        let coreLocation = CLLocation(
            coordinate: CLLocationCoordinate2DMake(123.12, 123.123),
            altitude: 30.0,
            horizontalAccuracy: 10,
            verticalAccuracy: 0,
            course: 180,
            speed: 20,
            timestamp: Date(timeIntervalSince1970: 1234)
        )

        let advertisingInfo = AdvertisingInfo.Builder()
            .set(isLimitedAdTrackingEnabled: false)
            .set(advertisingId: "123")
            .build()

        let networkInfo = NetworkInfo(bssid: "bssid_goes_here", ssid: "ssid_goes_here", carrierName: "carrier_goes_here")
        let deviceInfo = DeviceCollectingFields(isCharging: false, deviceModel: "iPhone9,4", osVersion: "iOS 11.0.1")

        let info = CollectingFields.Builder(configuration: .default)
            .set(location: coreLocation)
            .set(network: networkInfo)
            .set(deviceInfo: deviceInfo)
            .build()

        return OpenLocateLocation(
            timestamp: coreLocation.timestamp,
            advertisingInfo: advertisingInfo,
            collectingFields: info
        )
    }

    override func setUp() {
        dataSource = LocationList()
        _ = dataSource!.clear()
    }

    func testAddLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        do {
            try locations.add(location: testLocation)
        } catch let error {
            debugPrint(error.localizedDescription)
            XCTFail("Add Location error")
        }

        // Then
        XCTAssertEqual(locations.count, 1)
    }

    func testAddMultipleLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        // Then
        XCTAssertEqual(locations.count, 3)
    }

    func testPopLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)
        let popped = locations.all()
        locations.clear()

        // Then
        XCTAssertEqual(popped.count, 4)
        XCTAssertEqual(locations.count, 0)
    }

    func testFirstLocation() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)
        let firstIndexedLocation = locations.first()

        // Then
        do {
            let firstLocation = try OpenLocateLocation(data: firstIndexedLocation!.data,
                                                       createdAt: firstIndexedLocation!.timestamp)
            XCTAssertEqual(firstLocation.locationFields.coordinates?.latitude,
                           testLocation.locationFields.coordinates?.latitude)
            XCTAssertEqual(firstLocation.locationFields.coordinates?.longitude,
                           testLocation.locationFields.coordinates?.longitude)
            XCTAssertEqual(firstLocation.locationFields.course, testLocation.locationFields.course)
            XCTAssertEqual(firstLocation.locationFields.speed, testLocation.locationFields.speed)
            XCTAssertEqual(firstLocation.deviceInfo.isCharging, testLocation.deviceInfo.isCharging)
            XCTAssertEqual(firstLocation.deviceInfo.deviceModel, testLocation.deviceInfo.deviceModel)
            XCTAssertEqual(firstLocation.locationFields.timestamp!.timeIntervalSince1970,
                           testLocation.locationFields.timestamp!.timeIntervalSince1970,
                           accuracy: 0.1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
