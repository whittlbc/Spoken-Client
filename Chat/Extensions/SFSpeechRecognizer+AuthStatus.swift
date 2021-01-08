//
//  SFSpeechRecognizer+AuthStatus.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Speech

extension SFSpeechRecognizer {
    
    class func isAuthed() -> Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }
}
