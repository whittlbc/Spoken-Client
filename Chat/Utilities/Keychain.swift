//
//  Keychain.swift
//  Chat
//
//  Created by Ben Whittle on 12/9/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

public enum Keychain {
    
    // Available keychain operation actions
    enum Action {
        case add
        case get
        case update
        case delete
    }
    
    // Add token to keychain for given server.
    static func addToken(_ token: String, forServer server: String) throws {
        // Convert token from string to data.
        let tokenData = token.data(using: String.Encoding.utf8)!
        
        // Build query to add item to keychain.
        let addQuery = Keychain.buildQuery(forAction: Action.add, server: server, tokenData: tokenData)
        
        // Add the item to the keychain.
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        // Ensure the operation succeeded.
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // Get token from keychain for given server.
    static func getToken(forServer server: String) throws -> String {
        // Build query to get item from keychain.
        let getQuery = Keychain.buildQuery(forAction: Action.get, server: server)
        
        // Get the item.
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        
        // Ensure the item was found.
        guard status != errSecItemNotFound else {
            throw KeychainError.noToken
        }
        
        // Ensure the item was found successfully.
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        // Extract token from item.
        guard let existingItem = item as? [String : Any],
            let tokenData = existingItem[kSecValueData as String] as? Data,
            let token = String(data: tokenData, encoding: String.Encoding.utf8)
        else {
            throw KeychainError.unexpectedTokenData
        }
        
        return token
    }
    
    // Update token on keychain for given server.
    static func updateToken(_ token: String, forServer server: String) throws {
        // Build dictionary of attrs to update, including the new token.
        let attrsToUpdate: [String: Any] = [
            kSecValueData as String: token.data(using: String.Encoding.utf8)!
        ]
        
        // Build query to update item on keychain.
        let updateQuery = Keychain.buildQuery(forAction: Action.update, server: server)
        
        // Update the item on the keychain.
        let status = SecItemUpdate(updateQuery as CFDictionary, attrsToUpdate as CFDictionary)
        
        // Ensure the item was found.
        guard status != errSecItemNotFound else {
            throw KeychainError.noToken
        }
        
        // Ensure the item was updated successfully.
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // Delete token from keychain for given server.
    static func deleteToken(forServer server: String) throws {
        // Build query to delete item from keychain.
        let deleteQuery = Keychain.buildQuery(forAction: Action.delete, server: server)
        
        // Delete the item from the keychain.
        let status = SecItemDelete(deleteQuery as CFDictionary)
        
        // Ensure the operation succeeded.
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // Update existing token or add new token to keychain for provided server.
    static func upsertToken(_ token: String, forServer server: String) throws {
        do {
            try Keychain.updateToken(token, forServer: server)
        } catch KeychainError.noToken {
            try Keychain.addToken(token, forServer: server)
        }
    }
    
    // Build a keychain item query for a given action.
    private static func buildQuery(forAction: Action, server: String, tokenData: Data? = nil, itemClass: CFString = kSecClassInternetPassword) -> [String: Any] {
        precondition(tokenData != nil || forAction != Action.add, "token is required when building query to add item")
        
        // Create new query
        var query: [String: Any] = [
            kSecClass as String: itemClass,
            kSecAttrServer as String: server,
        ]
        
        switch forAction {
        case .add:
            query[kSecValueData as String] = tokenData!
        case .get:
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            query[kSecReturnData as String] = true
        default:
            break
        }
        
        return query
    }
}
