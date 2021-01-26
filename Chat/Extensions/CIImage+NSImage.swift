//
//  CIImage+NSImage.swift
//  Chat
//
//  Created by Ben Whittle on 1/26/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

extension CIImage {
    
    var nsImage: NSImage {
        let rep = NSCIImageRep(ciImage: self)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }
}

