//
//  Icon.swift
//  Chat
//
//  Created by Ben Whittle on 12/17/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

public enum Icon {
    
    // Get an image from assets by name.
    static func assetImageForName(_ name: String) -> NSImage {
        guard let image = NSImage(named: NSImage.Name(name)) else {
            fatalError("No image inside assets named: \(name)")
        }
        
        return image
    }
    
    // Circle icon with plus in it.
    static var plusCircle: NSImage { Icon.assetImageForName("plus-circle") }
}
