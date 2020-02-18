//
//  ErrorLogger.swift
//  Zynced
//
//  Created by Pascal Braband on 17.02.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import Foundation

struct ErrorLogItem: Codable, Equatable {
    var date: Date
    var type: String
    var message: String
}




class ErrorLogger {
    
    private static let configurationsSuiteName = (Bundle.main.bundleIdentifier ?? "de.pascalbraband.zynced") + ".error-log"
    private static let defaults = UserDefaults.init(suiteName: ErrorLogger.configurationsSuiteName)!
    
    
    /**
     Creates a new `ErrorLogItem` with the given parameters and then appends it to the list of items for the given id.
     
     - parameters:
        - id: The identifier, to which the new `ErrorLogItem` should be associated
        - date: The occurance date of the error for the new `ErrorLogItem`
        - message: The error message for the new `ErrorLogItem`
     */
    static func write(for id: String, date: Date, type errorType: Error, message: String) throws {
        // Load all ErrorLogItem's for the given id
        var errorLogItems = [ErrorLogItem]()
        if let previousItemsData = defaults.object(forKey: id) as? Data {
            if let previousItems = try? PropertyListDecoder().decode([ErrorLogItem].self, from: previousItemsData) {
                errorLogItems = previousItems
            }
        }
        
        // Create new ErrorLogItem
        let errorTypeString = String(describing: type(of: errorType)) + "." + String(describing: errorType.self)
        let item = ErrorLogItem(date: date, type: errorTypeString, message: message)
        
        // Append to the previous items and save
        errorLogItems.append(item)
        let errorLogData = try PropertyListEncoder().encode(errorLogItems)
        defaults.set(errorLogData, forKey: id)
        defaults.synchronize()
    }
    
    
    /**
     Removes all saved `ErrorLogItem`'s for a given key.
     
     - parameters:
        - id: The identifier, for which the `ErrorLogItem`'s should be removed
     */
    static func clean(for id: String) {
        defaults.removeObject(forKey: id)
        defaults.synchronize()
    }
    
    
    /**
     Reads all saved `ErrorLogItem`'s for a given key.
     */
    static func read(for id: String) throws -> [ErrorLogItem]? {
        if let errorLogData = defaults.object(forKey: id) as? Data {
            return try PropertyListDecoder().decode([ErrorLogItem].self, from: errorLogData)
        }
        return nil
    }
    
    
    /**
     Removes all configurations saved in the User Defaults.
     */
    static func removeAll() {
        defaults.removePersistentDomain(forName: configurationsSuiteName)
        defaults.synchronize()
    }
}
