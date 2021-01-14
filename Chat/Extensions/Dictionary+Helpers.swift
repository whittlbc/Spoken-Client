//
//  Dictionary+Helpers.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

extension Dictionary {
    
    func listValues(forKeys orderedKeys: [Key]) -> [Value] {
        var vals = [Value]()
        
        for key in orderedKeys {
            if let val = self[key] {
                vals.append(val)
            }
        }
        
        return vals
    }
}
