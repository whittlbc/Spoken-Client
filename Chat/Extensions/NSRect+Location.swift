//
//  NSRect+Location.swift
//  Chat
//
//  Created by Ben Whittle on 12/17/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

extension NSRect {
    
    // Check if the given point is inside this rect.
    func isLocationInside(_ loc: NSPoint) -> Bool {
        loc.x >= 0 && loc.x <= size.width && loc.y >= 0 && loc.y <= size.height
    }
}
