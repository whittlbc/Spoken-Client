//
//  Config.swift
//  Chat
//
//  Created by Ben Whittle on 12/9/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

// Global app config
public enum Config {
    
    // Environment variable keys
    enum Keys {
        static let env = "ENV"
        static let apiURL = "API_URL"
    }

    // App environment options
    enum Env: String {
        case dev, prod
    }
    
    // Info.plist as dictionary
    private static let infoDict: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        
        return dict
    }()
    
    // Current app environment
    static let env: Env = {
        // Get "ENV" environment variable string from plist dict.
        guard let environment = Config.infoDict[Keys.env] as? String else {
            fatalError(Config.notSetMessage(Keys.env))
        }
        
        // Get the proper Env enum for this environment variable
        guard let env = Env(rawValue: environment) else {
            fatalError("Unsupported config env: \(environment)")
        }
        
        return env
    }()

    // Base URL for API interactions.
    static let apiURL: String = {
        guard let apiURL = Config.infoDict[Keys.env] as? String else {
            fatalError(Config.notSetMessage(Keys.env))
        }
        
        return apiURL
    }()
    
    private static func notSetMessage(_ envVarName: String) -> String {
        return "\(envVarName) not set in plist for this environment."
    }
}
