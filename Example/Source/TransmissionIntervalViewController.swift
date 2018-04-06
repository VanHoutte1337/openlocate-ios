//
//  TransmissionIntervalTableViewController.swift
//  iOS Example
//
//  Created by Mohammad Kurabi on 3/7/18.
//  Copyright © 2018 OpenLocate. All rights reserved.
//

import UIKit

class TransmissionIntervalViewController: UITableViewController {

    // 1 min, 5 min, 1 hour, 6 hours, 12 hours, 1 day
    private let intervals = [60.0, 300.0, 3600.0, 21600.0, 43200.0, 86400.0]

    private var selectedIndexPath: IndexPath?

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return intervals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let interval = intervals[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "IntervalCell", for: indexPath)
        cell.textLabel?.text = "\(Int(interval / 60)) minutes"

        if interval == UserDefaults.standard.double(forKey: "TransmissionInterval") {
            cell.accessoryType = .checkmark
            selectedIndexPath = indexPath
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedIndexPath = self.selectedIndexPath, let cell = tableView.cellForRow(at: selectedIndexPath) {
            cell.accessoryType = .none
        }
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            UserDefaults.standard.set(intervals[indexPath.row], forKey: "TransmissionInterval")
            UserDefaults.standard.synchronize()

            (UIApplication.shared.delegate as? AppDelegate)?.configureOpenLocate()
        }
        selectedIndexPath = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
