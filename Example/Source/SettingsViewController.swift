//
//  SettingsViewController.swift
//  iOS Example
//
//  Created by Mohammad Kurabi on 3/7/18.
//  Copyright © 2018 OpenLocate. All rights reserved.
//

import UIKit
import OpenLocate
class SettingsViewController: UITableViewController {

    @IBOutlet weak var transmissionIntervalValueLabel: UILabel!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let transmissionInterval = UserDefaults.standard.double(forKey: "TransmissionInterval")
        if transmissionInterval > 0 {
            transmissionIntervalValueLabel.text = "\(Int(transmissionInterval / 60)) minutes"
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            OpenLocate.shared.sendData(onCompletion: { [weak self] (success) in
                let message = success ? "Data Sent Successfully" : "Could not send data"
                let alertVC = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alertVC.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                self?.present(alertVC, animated: true, completion: nil)

                tableView.deselectRow(at: indexPath, animated: true)
            })
        }
    }
}
