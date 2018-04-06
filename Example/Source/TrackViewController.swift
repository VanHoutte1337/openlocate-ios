//
//  TrackViewController.swift
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
import CoreLocation

class TrackViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var authorizationStatusSegmentedControl: UISegmentedControl!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var appSettingsButton: UIButton!
    @IBOutlet weak var sdkVersionLabel: UILabel!

    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.titleView = UIImageView(image: UIImage(named: "tab_logo"))

        configureUI()

        if OpenLocate.shared.isTrackingEnabled {
            onStartTracking()
        }

        locationManager.delegate = self
    }

    @IBAction func startTracking(_ sender: Any) {
        OpenLocate.shared.startTracking()
        onStartTracking()
    }

    @IBAction func stopTracking(_ sender: Any) {
        OpenLocate.shared.stopTracking()
        onStopTracking()
    }

    @IBAction func didChangeAuthPermission(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            UserDefaults.standard.set(CLAuthorizationStatus.authorizedAlways.rawValue,
                                      forKey: "AuthorizationStatus")
        } else {
            UserDefaults.standard.set(CLAuthorizationStatus.authorizedWhenInUse.rawValue,
                                      forKey: "AuthorizationStatus")
        }
        UserDefaults.standard.synchronize()

        (UIApplication.shared.delegate as? AppDelegate)?.configureOpenLocate()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        errorLabel.isHidden = false
        appSettingsButton.isHidden = false

        switch status {
        case .denied:
            errorLabel.text = "Location Permission Denied"
        case .restricted:
            errorLabel.text = "Location Services is Restricted"
        default:
            errorLabel.isHidden = true
            appSettingsButton.isHidden = true
        }
    }

    @IBAction func didTapAppSettingsButton() {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(appSettings)
            }
        }
    }

    private func configureUI() {
        startButton.layer.borderColor = UIColor.blue.cgColor
        stopButton.layer.borderColor = UIColor.red.cgColor
        appSettingsButton.layer.borderColor = UIColor.blue.cgColor

        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "x"
        let appBuildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "N/A"
        let sdkVersion = Bundle(for: OpenLocate.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "x"
        let iosVersion = UIDevice.current.systemVersion
        sdkVersionLabel.text = "OpenLocate v\(appVersion)(\(appBuildNumber))\nSDK v\(sdkVersion) · iOS \(iosVersion)"
    }

    private func onStartTracking() {
        startButton.isHidden = true
        stopButton.isHidden = false
        authorizationStatusSegmentedControl.isHidden = true
    }

    private func onStopTracking() {
        startButton.isHidden = false
        stopButton.isHidden = true
        authorizationStatusSegmentedControl.isHidden = false
    }
}
