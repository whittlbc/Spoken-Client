//
//  NSView+Subviews.swift
//  Chat
//
//  Created by Ben Whittle on 12/25/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

extension NSView {
    
    func firstSubview<T>(ofType: T.Type) -> T? {
        for sv in subviews {
            if let subview = sv as? T {
                return subview
            }
        }
        
        return nil
    }
}
