//
//  Color.swift
//  Chat
//
//  Created by Ben Whittle on 12/27/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

public enum Color {
    
    static func fromRGBA(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> NSColor {
        return NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }
}
