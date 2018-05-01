//
//  NetworkInfo.swift
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
import SystemConfiguration.CaptiveNetwork
import CoreTelephony

public struct NetworkInfo {

    var bssid: String?
    var ssid: String?
    var carrierName: String?

    static func currentNetworkInfo() -> NetworkInfo {
        var networkInfo = NetworkInfo()
        if let interface = CNCopySupportedInterfaces() {
            for index in 0..<CFArrayGetCount(interface) {
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interface, index)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                if let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString),
                    let interfaceData = unsafeInterfaceData as? [String: AnyObject] {
                    networkInfo.bssid = interfaceData["BSSID"] as? String
                    networkInfo.ssid = interfaceData["SSID"] as? String
                } else {
                    // not connected wifi
                }
            }
        }
        if let carrierName = CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName {
            networkInfo.carrierName = carrierName
        }
        return networkInfo
    }
}
