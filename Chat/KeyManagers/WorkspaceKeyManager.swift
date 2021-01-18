//
//  WorkspaceKeyManager.swift
//  Chat
//
//  Created by Ben Whittle on 1/17/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import HotKey
import Carbon

// Manager for global hot-keys associated with the workspace window.
class WorkspaceKeyManager {
    
    // Currently used/supported keys.
    enum Key {
        case escKey
        case returnKey
        case commandKey
    }
    
    // Delegate that receives key up/down events associated with listeners.
    weak var delegate: WorkspaceKeyManagerDelegate?

    // Create global hotkey for escape key.
    private var escKeyListener: HotKey!
    
    // Create global hotkey for return key.
    private var returnKeyListener: HotKey!
    
    // Whether command key is currently down.
    private var commandKeyPressed = false
    
    // Whether command key listener is active or not.
    private var commandKeyListenerPaused = false
    
    init() {
        // Create all key listeners.
        createKeyListeners()
    }
    
    // Pause or start a key listener.
    func toggleKeyListener(forKey key: Key, pause: Bool) {
        switch key {
        case .escKey:
            escKeyListener.isPaused = pause
        case .returnKey:
            returnKeyListener.isPaused = pause
        case .commandKey:
            commandKeyListenerPaused = pause
        }
    }
    
    // Create all supported key listeners.
    private func createKeyListeners() {
        createEscKeyListener()
        createReturnKeyListener()
        createCommandKeyListener()
    }
    
    // Create escape key listener.
    private func createEscKeyListener() {
        escKeyListener = HotKey(key: .escape, modifiers: [])
        
        // Listen for escape key-down event.
        escKeyListener.keyDownHandler = { [weak self] in
            self?.delegate?.onEscDown()
        }
    }
    
    // Create return key listener.
    private func createReturnKeyListener() {
        returnKeyListener = HotKey(key: .return, modifiers: [])
        
        // Listen for escape key-down event.
        returnKeyListener.keyDownHandler = { [weak self] in
            self?.delegate?.onReturnDown()
        }
    }
    
    // Create command key listener.
    private func createCommandKeyListener() {
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] in
            if self?.commandKeyListenerPaused == true {
                return
            }
            
            let keys = $0.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            switch keys {
            // Handle command key-down event.
            case [.command], [.command, .capsLock]:
                if self?.commandKeyPressed == false {
                    self?.commandKeyPressed = true
                    self?.delegate?.onCommandDown()
                }
                
            // Handle command key-up event.
            default:
                if self?.commandKeyPressed == true && !keys.contains(.command) {
                    self?.commandKeyPressed = false
                    self?.delegate?.onCommandUp()
                }
            }
        }
    }
}


protocol WorkspaceKeyManagerDelegate: class {
    
    func onEscDown()

    func onReturnDown()
    
    func onCommandDown()
    
    func onCommandUp()
}
