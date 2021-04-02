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
        static let appName = "APP_NAME"
        static let appBundleID = "APP_BUNDLE_ID"
        static let agoraAppID = "AGORA_APP_ID"
    }

    // App environment options
    enum Env: String {
        case dev
        case prod
    }
    
    // Info.plist as dictionary
    private static let infoDict: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        
        return dict
    }()
    
    // Get a required environment variable of string type.
    private static func getRequiredStringEnvVar(forKey key: String) -> String {
        guard let envVar = Config.infoDict[key] as? String else {
            fatalError("\(key) not set in plist for this environment.")
        }
        
        return envVar
    }
        
    // Current app environment
    static let env: Env = {
        // Get "ENV" environment variable string from plist dict.
        let environment = Config.getRequiredStringEnvVar(forKey: Keys.env)
        
        // Get the proper Env enum for this environment variable
        guard let env = Env(rawValue: environment) else {
            fatalError("Unsupported config env: \(environment)")
        }
        
        return env
    }()

    // Base URL for API interactions.
    static let apiURL = Config.getRequiredStringEnvVar(forKey: Keys.apiURL)
    
    // Host of apiURL
    static let apiHost: String = {
        guard let url = URL(string: Config.apiURL), let host = url.host else {
            fatalError("API_URL is not a valid url -- can't parse host")
        }
        
        return host
    }()
    
    // App name.
    static let appName = Config.getRequiredStringEnvVar(forKey: Keys.appName)
    
    // App bundle identifier.
    static let appBundleID = Config.getRequiredStringEnvVar(forKey: Keys.appBundleID)
    
    // Agora App ID.
    static let agoraAppID = Config.getRequiredStringEnvVar(forKey: Keys.agoraAppID)
}
