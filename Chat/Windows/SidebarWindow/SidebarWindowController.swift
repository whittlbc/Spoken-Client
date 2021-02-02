//
//  SidebarWindowController.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Controller for sidebar window.
class SidebarWindowController: NSWindowController, NSWindowDelegate {
    
    // Controller for workspace window.
    private var workspaceWindowController: WorkspaceWindowController!
    
    // Proper init to call when creating this class.
    convenience init() {
        self.init(window: nil)
    }
    
    // Override delegated init.
    private override init(window: NSWindow?) {
        precondition(window == nil, "call init() with no window")
        
        // Initialize with new sidebar window.
        super.init(window: SidebarWindow())
        
        // Assign self as new sidebar window's delegate.
        self.window!.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Show main window and add child windows.
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        // Add child windows.
        addChildWindows()
        
        // Run the UIEvent queue.
        startUIEventQueue()
    }
    
    // Add child windows to sidebar window.
    private func addChildWindows() {
        addWorkspaceWindow()
    }
        
    // Add workspace window as a child window.
    private func addWorkspaceWindow() {
        // Create new workspace window controller.
        workspaceWindowController = WorkspaceWindowController()
        
        // Add workspace window as top-most child window of sidebar window.
        window!.addChildWindow(workspaceWindowController.window!, ordered: NSWindow.OrderingMode.above)
        
        // Load current workspace.
        workspaceWindowController.loadCurrentWorkspace()
    }
    
    // Start the UIEventQueue.
    private func startUIEventQueue() {
        uiEventQueue.start { [weak self] eventWrapper in
            self?.onNewUIEvent(withWrapper: eventWrapper)
        }
    }
    
    // Handle new UIEvents.
    private func onNewUIEvent(withWrapper eventWrapper: UIEventWrapper) {
        switch eventWrapper.context {
                    
        // New Workspace UI Event.
        case .workspace(id: let workspaceId):
            handleWorkspaceUIEvent(eventWrapper.event, workspaceId: workspaceId)
        }
    }
    
    // Handle Workspace UI Event.
    private func handleWorkspaceUIEvent(_ event: UIEvent, workspaceId: String) {
        workspaceWindowController.handleUIEvent(event, forWorkspaceId: workspaceId)
    }
}
