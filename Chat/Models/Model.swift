//
//  Model.swift
//  Chat
//
//  Created by Ben Whittle on 1/12/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

protocol Model: Codable, Identifiable {
    
    // Name of model represented as a lowercased string.
    static var modelName: String { get }
    
    func forCache() -> Self
    
    // Public model identifier.
    var id: String { get set }
}
