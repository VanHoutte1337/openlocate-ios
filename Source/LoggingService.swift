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

public class LoggingService: LoggingServiceProtocol {
    static var shared = LoggingService()
    
    let fileName = "Accurat"
    let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let fileURL: URL
    
    init() {
        fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
    }

    func log(_ value: String) {
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(value.data(using: .utf8)!)
            fileHandle.closeFile()
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
