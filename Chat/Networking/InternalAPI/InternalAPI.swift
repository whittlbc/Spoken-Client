//
//  InternalAPI.swift
//  Chat
//
//  Created by Ben Whittle on 12/9/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

public class InternalAPI: API {
    
    static let authTokenName = "Chat-Api-Token"
    
    convenience init() {
        self.init(baseURL: Config.apiURL, authHeaderName: InternalAPI.authTokenName)
    }
    
    private override init(baseURL: String, authHeaderName: String? = nil) {
        super.init(baseURL: baseURL, authHeaderName: authHeaderName)
    }

    override func getAuthHeaderToken() -> String? {
        return try? Keychain.getToken(forServer: Config.apiHost)
    }
    
    // HACK --> Remove this when starting to build sign-in flow
    override func isAuthed() -> Bool { true }
}

public let api = InternalAPI()
