//
//  API.swift
//  Chat
//
//  Created by Ben Whittle on 12/9/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

public class API {
    
    var baseURL: String
    
    var authHeaderName: String?
    
    // Custom headers to include with each API request.
    var headers: [String: String] { [:] }
    
    init(baseURL: String, authHeaderName: String? = nil) {
        self.baseURL = baseURL
        self.authHeaderName = authHeaderName
    }
    
    func getAuthHeaderToken() -> String? { nil }
    
    func buildHeaders() -> [String: String] {
        var requestHeaders = headers
        
        if let authHeaderName = self.authHeaderName, let authHeaderToken = getAuthHeaderToken() {
            requestHeaders[authHeaderName] = authHeaderToken
        }
        
        return requestHeaders
    }
    
    func isAuthed() -> Bool { getAuthHeaderToken() != nil }
}
