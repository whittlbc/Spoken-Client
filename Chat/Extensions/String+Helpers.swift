//
//  String+Helpers.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

extension String {
    
    func asPlural() -> String {
        // Return new String with no changes if empty or already ends in "s".
        if self.isEmpty || self.last! == "s"  {
            return String(self)
        }
        
        // Replace "y" with "ies" if ends in "y".
        if self.last! == "y" {
            return self[..<endIndex] + "ies"
        }
        
        // Default is just add an "s".
        return self + "s"
    }
}
