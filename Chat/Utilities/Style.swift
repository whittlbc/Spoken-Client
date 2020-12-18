//
//  Style.swift
//  Chat
//
//  Created by Ben Whittle on 12/17/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Shadow style config struct.
struct Shadow {
    
    // General offset of shadow from center.
    var offset: CGSize
    
    // Shadow blur amount.
    var radius: CGFloat
    
    // Shadow color.
    var color: CGColor
    
    // Shadow opacity.
    var opacity: Float
    
    init(offset: CGSize, radius: CGFloat, color: CGColor = CGColor.black, opacity: Float = 1.0) {
        self.offset = offset
        self.radius = radius
        self.color = color
        self.opacity = opacity
    }
}
