//
//  DataSource.swift
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

protocol LocationDataSourceType {

    var count: Int { get }

    func add(location: OpenLocateLocation) throws
    func addAll(locations: [OpenLocateLocation])

    func first() -> OpenLocateLocation?

    func all() -> [OpenLocateLocation]
    func all(starting: Date, ending: Date) -> [OpenLocateLocation]

    func clear()
    func clear(before: Date)
}

final class LocationDatabase: LocationDataSourceType {

    private enum Constants {
        static let tableName = "Location"
        static let columnId = "_id"
        static let columnLocation = "location"
        static let columnCreatedAt = "created_at"
    }

    private var database: Database
    private let currentDatabaseVersion: Int = 2

    func add(location: OpenLocateLocation) throws {
        let query = "INSERT INTO " +
        "\(Constants.tableName) " +
        "(\(Constants.columnLocation)) " +
        "VALUES (?);"

        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(args: [location.data])
            .build()

        try database.execute(statement: statement)
    }

    func addAll(locations: [OpenLocateLocation]) {
        if locations.isEmpty {
            return
        }

        if locations.count == 1 {
            do {
                try add(location: locations.first!)
            } catch let error {
                debugPrint(error.localizedDescription)
            }
            return
        }

        database.begin()
        for location in locations {
            do {
                try add(location: location)
            } catch let error {
                debugPrint(error.localizedDescription)
                database.rollback()
                return
            }
        }
        database.commit()
    }

    var count: Int {
        let query = "SELECT COUNT(*) FROM \(Constants.tableName)"

        let statement = SQLStatement.Builder()
        .set(query: query)
        .set(cached: true)
        .build()

        var count = -1
        do {
            let result = try database.execute(statement: statement)
            _ = result.next()
            count = Int(result.intValue(column: 0))

            return count
        } catch let error {
            debugPrint(error.localizedDescription)
            return count
        }
    }

    func clear() {
        let query = "DELETE FROM \(Constants.tableName)"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .build()

        do {
            try database.execute(statement: statement)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func clear(before: Date) {
        let query = "DELETE FROM \(Constants.tableName) WHERE created_at <= ?;"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(args: [before])
            .build()

        do {
            try database.execute(statement: statement)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func first() -> OpenLocateLocation? {
        let query = "SELECT * FROM \(Constants.tableName) LIMIT 1"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        do {
            let result = try database.execute(statement: statement)
            if result.next() {
                let data = result.dataValue(column: Constants.columnLocation)
                let createdAtDate = result.dateValue(column: Constants.columnCreatedAt)

                if let data = data, let createdAtDate = createdAtDate {
                    return try OpenLocateLocation(data: data, createdAt: createdAtDate)
                }
            }
        } catch let error {
            debugPrint(error.localizedDescription)
        }

        return nil
    }

    func all() -> [OpenLocateLocation] {
        let query = "SELECT * FROM \(Constants.tableName) ORDER BY created_at ASC"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        var locations = [OpenLocateLocation]()

        do {
            let result = try database.execute(statement: statement)

            while result.next() {
                let data = result.dataValue(column: Constants.columnLocation)
                let createdAtDate = result.dateValue(column: Constants.columnCreatedAt)

                if let data = data, let createdAtDate = createdAtDate {
                    locations.append(
                        try OpenLocateLocation(data: data, createdAt: createdAtDate)
                    )
                }
            }

        } catch let error {
            debugPrint(error.localizedDescription)
        }

        return locations
    }

    func all(starting: Date, ending: Date) -> [OpenLocateLocation] {
        let query = """
                    SELECT * FROM \(Constants.tableName) WHERE created_at > ? AND created_at < ? ORDER BY created_at ASC
                    """
        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(args: [starting, ending])
            .set(cached: true)
            .build()
        
        LoggingService.shared.log("Getting locations with the following query: \(statement.query)")

        var locations = [OpenLocateLocation]()
        do {
            let result = try database.execute(statement: statement)
            while result.next() {

                let data = result.dataValue(column: Constants.columnLocation)
                let createdAtDate = result.dateValue(column: Constants.columnCreatedAt)

                if let data = data, let createdAtDate = createdAtDate {
                    locations.append(
                        try OpenLocateLocation(data: data, createdAt: createdAtDate)
                    )
                }
            }
        } catch let error {
            debugPrint(error.localizedDescription)
        }

        return locations
    }

    init(database: Database) {
        self.database = database
        createTableIfNotExists()
    }

    private func createTableIfNotExists() {

        let userVersion = database.userVersion
        if userVersion != currentDatabaseVersion {
            dropTableIfExists()
        }

        let query = "CREATE TABLE IF NOT EXISTS " +
        "\(Constants.tableName) (" +
        "\(Constants.columnId) INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "\(Constants.columnLocation) BLOB NOT NULL, " +
        "\(Constants.columnCreatedAt) datetime default current_timestamp" +
        "); "

        let index = "CREATE INDEX IF NOT EXISTS `\(Constants.columnCreatedAt)_index` " +
        "ON `\(Constants.tableName)` (`\(Constants.columnCreatedAt)` ASC);"

        let createTableStatement = SQLStatement.Builder()
        .set(query: query)
        .build()

        let createIndexStatement = SQLStatement.Builder()
            .set(query: index)
            .build()

        do {
            try database.execute(statement: createTableStatement)
            try database.execute(statement: createIndexStatement)
            database.userVersion = currentDatabaseVersion
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    private func dropTableIfExists() {
        let dropTableStatement = SQLStatement.Builder()
            .set(query: "DROP TABLE IF EXISTS \(Constants.tableName)")
            .build()

        do {
            try database.execute(statement: dropTableStatement)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
}

final class LocationList: LocationDataSourceType {

    private var locations: [OpenLocateLocation]

    var count: Int {
        return self.locations.count
    }

    init() {
        self.locations = [OpenLocateLocation]()
    }

    func add(location: OpenLocateLocation) {
        self.locations.append(location)
    }

    func addAll(locations: [OpenLocateLocation]) {
        self.locations.append(contentsOf: locations)
    }

    func first() -> OpenLocateLocation? {
        return self.locations.first
    }

    func all() -> [OpenLocateLocation] {
        return self.locations
    }

    func all(starting: Date, ending: Date) -> [OpenLocateLocation] {
        var locations = [OpenLocateLocation]()
        self.locations.forEach { location in
            if location.timestamp > starting && location.timestamp < ending {
                locations.append(location)
            }
        }
        return locations
    }

    func clear() {
        self.locations.removeAll()
    }

    func clear(before: Date) {
        var locations = [OpenLocateLocation]()
        self.locations.forEach { location in
            if location.timestamp <= before {
                locations.append(location)
            }
        }
        self.locations = locations
    }
}
