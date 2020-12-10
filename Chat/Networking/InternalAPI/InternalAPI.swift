//
//  InternalAPI.swift
//  Chat
//
//  Created by Ben Whittle on 12/9/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

// This app's primary internal API.
public class InternalAPI: API {
    
    // Static version of the auth header name
    static let authTokenName = "Chat-Api-Token"
    
    // Init an InternalAPI instance with a baseURL from env vars and the auth header as its only header.
    convenience init() {
        self.init(baseURL: Config.apiURL, authHeaderName: InternalAPI.authTokenName)
    }
    
    // Override delegated init
    private override init(baseURL: String, authHeaderName: String? = nil, headers: [String: String] = [:]) {
        super.init(baseURL: baseURL, authHeaderName: authHeaderName, headers: headers)
    }

    // Fetch the auth header token from the user's keychain.
    override func getAuthHeaderToken() -> String? {
        return try? Keychain.getToken(forServer: Config.apiHost)
    }
    
    // HACK --> Remove this when starting to build sign-in flow
    override func isAuthed() -> Bool { true }
}

// Global internal API instance.
public let api = InternalAPI()
