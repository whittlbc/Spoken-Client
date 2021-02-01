//
//  API.swift
//  Chat
//
//  Created by Ben Whittle on 12/9/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Networking

public class API: NetworkingService {
    
    // Base URL for all API client requests
    var baseURL: String
    
    // Name of auth header to use in client requests.
    // Should not be included in headers params passed into init.
    var authHeaderName: String?
    
    // API client - will be auto-initialized with url and headers during init.
    public var network: NetworkingClient
    
    init(baseURL: String, authHeaderName: String? = nil, headers: [String: String] = [:]) {
        self.baseURL = baseURL
        self.authHeaderName = authHeaderName
        
        // Create new API client.
        network = NetworkingClient(baseURL: baseURL)
        
        // Build and set headers for client.
        buildClientHeaders(headers)
    }
    
    // Get the auth header value (token). Should be overridden by a function that
    // fetches this value from either an environment variable or the user's keychain.
    func getAuthHeaderToken() -> String? { nil }
    
    // Check whether the API client is current "authed" by checking if its auth header has a value.
    func isAuthed() -> Bool { getAuthHeaderToken() != nil }

    // Construct a dictionary of headers (default + auth headers) and assign these to the API client.
    func buildClientHeaders(_ defaultHeaders: [String:String] = [:]) {
        // Start with default headers dictionary.
        var requestHeaders = defaultHeaders
        
        // Add auth header if both name and value exist and it doesn't already exist in defaultHeaders.
        if let authHeaderName = self.authHeaderName,
           let authHeaderToken = getAuthHeaderToken(),
           defaultHeaders[authHeaderName] == nil {
            requestHeaders[authHeaderName] = authHeaderToken
        }
        
        // Assign headers to client.
        network.headers = requestHeaders
    }
}

