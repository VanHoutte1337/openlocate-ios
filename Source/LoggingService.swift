//
//  LoggingService.swift
//  OpenLocate
//
//  Created by Mathias Van Houtte on 11/06/2018.
//  Copyright © 2018 OpenLocate. All rights reserved.
//

import UIKit

protocol LoggingServiceProtocol {
    func log(_ value: String, key: String)
    func clear()
    func getLogs() -> String
    func getExportPath() -> URL
}

public class LoggingService: LoggingServiceProtocol {
    static var shared = LoggingService()
    
    let fileName = "Accurat"
    let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let fileURL: URL
    
    init() {
        fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
    }
    
    func log(_ value: String, key: String = "") {
        do {
            let date = Date().toString(dateFormat:"dd/MM/yy HH:mm:ss")
            let valueString = "\(date) - \(key.uppercased())\(value) \n"
            
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: fileURL.path) {
                try valueString.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            else {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(valueString.data(using: .utf8)!)
                fileHandle.closeFile()
            }
            
        } catch {
            print("failed with error: \(error)")
        }
    }
    
    func clear() {
        do {
            try "".write(to: fileURL, atomically: false, encoding: .utf8)
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
    
    func getExportPath() -> URL {
        return fileURL
    }
}

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
