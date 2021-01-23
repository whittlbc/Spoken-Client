//
//  UserDefaults+RawRepresentable.swift
//  Chat
//
//  Created by Ben Whittle on 1/23/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Combine

extension UserDefaults {
    
    func value<Persisted: RawRepresentable>(of type: Persisted.Type, forKey key: String, withDefault defaultValue: Persisted) -> Persisted {
        guard let rawValue = UserDefaults.standard.value(forKey: key) as! Persisted.RawValue? else {
            return defaultValue
        }
        
        return Persisted(rawValue: rawValue)!
    }
}

@propertyWrapper
struct UserDefault<Persisted: RawRepresentable> {
    
    let key: String
    
    let defaultValue: Persisted
    
    var storage: UserDefaults = .standard
    
    let subject: CurrentValueSubject<Persisted, Never>

    init(wrappedValue: Persisted, key: String) {
        self.key = key
        self.defaultValue = wrappedValue
        self.subject = .init(storage.value(of: Persisted.self, forKey: key, withDefault: defaultValue))
    }
    
    var wrappedValue: Persisted {
        get {
            storage.value(of: Persisted.self, forKey: key, withDefault: defaultValue)
        }
        nonmutating set {
            storage.set(newValue.rawValue, forKey: key)
            subject.send(newValue)
        }
    }
    
    var projectedValue: CurrentValueSubject<Persisted, Never> {
       subject
    }
}

extension Bool: RawRepresentable {
    
    public init?(rawValue: Self) {
        self = rawValue
    }
    
    public var rawValue: Self {
        self
    }
}

extension Int: RawRepresentable {
    
    public init?(rawValue: Self) {
        self = rawValue
    }
    
    public var rawValue: Self {
        self
    }
}

extension String: RawRepresentable {
    
    public init?(rawValue: Self) {
        self = rawValue
    }
    
    public var rawValue: Self {
        self
    }
}

extension Optional: RawRepresentable where Wrapped: RawRepresentable {

    public init?(rawValue: Self) {
        self = rawValue
    }

    public var rawValue: Self {
        self
    }
}
