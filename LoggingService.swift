//
//  LoggingService.swift
//  OpenLocate
//
//  Created by Mathias Van Houtte on 11/06/2018.
//  Copyright © 2018 OpenLocate. All rights reserved.
//

import UIKit

protocol LoggingServiceProtocol {
    func log(_ value: String)
    func getLogs() -> String
}

class LoggingService: LoggingServiceProtocol {
    static var shared = LoggingService()
    
    let fileName = "Accurat"
    let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let fileURL: URL
    
    init() {
        fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
    }

    func log(_ value: String) {
        do {
            try value.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("failed with error: \(error)")
        }
    }
    
    func getLogs() -> String {
        do {
            let text = try String(contentsOf: fileURL, encoding: .utf8)
            return text
        }
        catch {
            print("failed with error: \(error)")
        }
        
        return ""
    }
}
