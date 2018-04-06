//
//  AppDelegate.swift
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

import UIKit
import OpenLocate
import Fabric
import Crashlytics
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? ) -> Bool {

        Fabric.with([Crashlytics.self])

        configureOpenLocate()

        return true
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        OpenLocate.shared.performFetchWithCompletionHandler(completionHandler)
    }

    func configureOpenLocate() {

        UserDefaults.standard.register(defaults: ["TransmissionInterval": Configuration.defaultTransmissionInterval,
                                                  "AuthorizationStatus": CLAuthorizationStatus.authorizedAlways.rawValue])

        if let token = Bundle.main.object(forInfoDictionaryKey: "Token") as? String,
            let uuid = Bundle.main.object(forInfoDictionaryKey: "ProviderId") as? String {

            let url = URL(string: "https://api.safegraph.com/v1/provider/\(uuid)/devicelocation")!
            let headers = ["Authorization": "Bearer \(token)"]
            let transmissionInterval = UserDefaults.standard.double(forKey: "TransmissionInterval")

            let endpoint = Configuration.Endpoint(url: url, headers: headers)
            let configuration = Configuration(endpoints: [endpoint],
                                              transmissionInterval: transmissionInterval,
                                              authorizationStatus: storedAuthorizationStatus())

            try? OpenLocate.shared.initialize(with: configuration)
        }
    }

    private func storedAuthorizationStatus() -> CLAuthorizationStatus {
        let authorizationStatusRaw = Int32(UserDefaults.standard.integer(forKey: "AuthorizationStatus"))
        return CLAuthorizationStatus(rawValue: authorizationStatusRaw) ?? .authorizedAlways
    }

}
