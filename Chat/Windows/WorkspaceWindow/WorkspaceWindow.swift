//
//  WorkspaceWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa
import HotKey
import Carbon

// Window housing all sidebar app functionality as it relates to a given workspace.
class WorkspaceWindow: FloatingWindow, ChannelDelegate {
    
    // Size of workspace window -- same as Sidebar.
    static let size = SidebarWindow.size
    
    // Origin of workspace window -- same as Sidebar.
    static let origin = SidebarWindow.origin
    
    // Right padding of workspace window as it pertains to its content.
    static let paddingRight: Float = 6
    
    // Style information for group of channel windows.
    enum ChannelsStyle {
        // X-position of the right edge of channels.
        static let rightEdge = Float(WorkspaceWindow.origin.x + WorkspaceWindow.size.width) - WorkspaceWindow.paddingRight
        
        // Distance between top of workspace window and top-most channel window.
        static let topOffset: Float = 240
        
        // Vertical spacing between channels.
        static let gutterSpacing: Float = 0
    }
    
    // Animation configuration for all child windows that this workspace window controls.
    enum AnimationConfig {
        
        // Configuration for channel window animations.
        enum ChannelWindows {
            // Time it takes for a channel window to update size and position during a state change.
            static let duration: CFTimeInterval = 0.13
            
            // Name of timing function to use for all channel window animations.
            static let timingFunctionName = CAMediaTimingFunctionName.easeOut
        }
    }
    
    // Current workspace represented in window.
    private var workspace: Workspace?
    
    // Ordered list of channels.
    private var channels = [Channel]()
    
    // Dictionary mapping a channel's id to its respective window.
    private var channelsMap = [String: ChannelWindow]()
    
    // Create global hotkey for escape key.
    private var escKeyListener: HotKey!
    
    // Create global hotkey for return key.
    private var returnKeyListener: HotKey!

    // Create global hotkey for command key.
    private var commandKeyListener: HotKey!
    
    private var commandKeyPressed = false
    
    // Override delegated init, size/position window on screen, and fetch workspaces.
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        // Position and size window on screen.
        repositionWindow(to: SidebarWindow.origin)
        resizeWindow(to: SidebarWindow.size)

        // Configure app permissions associated with this window.
        configurePermisssions()
        
        // Create global keypress listeners.
        createKeyListeners()
    }
    
    // Load the current workspace.
    func loadCurrentWorkspace() {
        // Render loading view.
        render(.loading)
        
        // HACK -- local testing
        workspace = Mocks.Workspaces.current
        channels = Mocks.Channels.all
        render(.loaded)
        
//        // Get current workspace.
//        dataProvider.workspace.current { [weak self] workspace, error in
//            // Handle any errors.
//            if let err = error {
//                self?.render(.failed(err))
//                return
//            }
//
//            // Handle no workspaces exist.
//            guard let ws = workspace else {
//                self?.render(.noWorkspacesExist)
//                return
//            }
//
//            // Set current workspace.
//            self?.workspace = ws
//
//            // Load current workspace members.
//            self?.loadWorkspaceMembers()
//        }
    }
    
    // Load the current workspace's members.
    func loadWorkspaceMembers() {
        // Ensure current workspace exists.
        guard let ws = workspace else {
            return
        }
        
        // Load list of members in current workspace.
        dataProvider.member.list(ids: ws.memberIds) { [weak self] _, error in
            // Load current workspace channels on success.
            error == nil ? self?.loadWorkspaceChannels() : self?.render(.failed(error!))
        }
    }
    
    // Load the current workspace's channels.
    func loadWorkspaceChannels() {
        // Ensure current workspace exists.
        guard let ws = workspace else {
            return
        }
        
        // Get list of channels in current workspace.
        dataProvider.channel.list(ids: ws.channelIds) { [weak self] channels, error in
            // Handle any errors.
            if let err = error {
                self?.render(.failed(err))
                return
            }
            
            // Set current channels.
            self?.channels = channels ?? [Channel]()
            
            // Render window as loaded.
            self?.render(.loaded)
        }
    }
    
    // Toggle on/off the key-event listeners active during recordings.
    func toggleRecordingKeyEventListeners(enable: Bool) {
        let isPaused = !enable
        escKeyListener.isPaused = isPaused
        returnKeyListener.isPaused = isPaused
    }
    
    // Seek permissions this app requries within this window.
    private func configurePermisssions() {
        AV.seekPermissions()
    }
    
    // Create listeners for all global key-bindings.
    private func createKeyListeners() {
        // Create escape key-down event handler.
        createEscKeyListener()
        
        // Create return key-down event handler.
        createReturnKeyListener()
        
        // Turn off all recording key listeners to start.
        toggleRecordingKeyEventListeners(enable: false)
        
        // Create command key event handlers.
        createCommandKeyListener()
    }
    
    // Create escape key listener.
    private func createEscKeyListener() {
        escKeyListener = HotKey(key: .escape, modifiers: [])
        
        // Listen for escape key-down event.
        escKeyListener.keyDownHandler = { [weak self] in
            self?.onEscPress()
        }
    }
    
    // Create return key listener.
    private func createReturnKeyListener() {
        returnKeyListener = HotKey(key: .return, modifiers: [])
        
        // Listen for escape key-down event.
        returnKeyListener.keyDownHandler = { [weak self] in
            self?.onReturnPress()
        }
    }
    
    private func createCommandKeyListener() {
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] in
            let keys = $0.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            switch keys {
            // Handle command key-down event.
            case [.command], [.command, .capsLock]:
                if self?.commandKeyPressed == false {
                    self?.commandKeyPressed = true
                    self?.onCommandKeyDown()
                }
                
            // Handle command key-up event.
            default:
                if self?.commandKeyPressed == true && !keys.contains(.command) {
                    self?.commandKeyPressed = false
                    self?.onCommandKeyUp()
                }
            }
        }
    }
    
    // Handle escape button key-down event.
    private func onEscPress() {
        findAndCancelActiveRecording()
    }
    
    // Handle return button key-down event.
    private func onReturnPress() {
        findAndSendActiveRecording()
    }
    
    // Handle command button key-down event.
    private func onCommandKeyDown() {
        startChannelPromptSpeechRecognizer()
    }
    
    // Handle command button key-up event.
    private func onCommandKeyUp() {
        stopSpeechRecognition()
    }

    // Handle individual channel window state updates as a group.
    func onChannelsRequireGroupUpdate(activeChannelId: String) {
        // Promote previous state to current state for all adjacent channel windows.
        for (channelId, channelWindow) in channelsMap {
            if channelId != activeChannelId {
                channelWindow.promotePreviousState()
            }
        }

        // Animate all channel windows to new sizes/positions based on state change.
        updateChannelSizesAndPositions(activeChannelId: activeChannelId)
    }
    
    private func startChannelPromptSpeechRecognizer() {
        AV.mic.startChannelPromptAnalyzer(onChannelPrompted: { [weak self] result in
            if let channelId = result as? String {
                self?.onChannelPromptedBySpeech(channelId: channelId)
            }
        })
    }
    
    private func stopSpeechRecognition() {
        AV.mic.stopSpeechRecognition()
    }
    
    func onChannelPromptedBySpeech(channelId: String) {
        // Get ordered list of existing channel windows.
        let channelWindows = getOrderedChannelWindows()

        // Find the index of the active channel window.
        let activeIndex = channelWindows.firstIndex{ $0.channel.id == channelId }
        
        // Ensure channel window index was found.
        guard let activeChannelIndex = activeIndex else {
            logger.error("Speech recognizer prompted channel that couldn't be found: \(channelId)")
            return
        }
                
        // Switch any channel windows currently in the previewing state to back to idle.
        unpreviewNonActiveChannelWindows(
            channelWindows: channelWindows,
            activeChannelIndex: activeChannelIndex
        )
    
        // Get the active window by index.
        let activeChannelWindow = channelWindows[activeChannelIndex]

        // Trigger channel window speech prompted handler.
        activeChannelWindow.onSpeechPrompted()
    }
    
    // Cancel the active recording if one exists.
    private func findAndCancelActiveRecording() {
        // See if there's an active recording taking place and cancel it if so.
        if let activeRecordingChannel = findActiveRecordingChannel() {
            activeRecordingChannel.cancelRecording()
        }
    }
    
    // Send the active recording if one exists.
    private func findAndSendActiveRecording() {
        // See if there's an active recording taking place and send it if so.
        if let activeRecordingChannel = findActiveRecordingChannel() {
            activeRecordingChannel.sendRecording()
        }
    }
    
    // Find the first channel with a recording state.
    private func findActiveRecordingChannel() -> ChannelWindow? {
        getOrderedChannelWindows().first(where: { $0.isRecording() })
    }
        
    // Create a new channel window for a given channel.
    private func createChannelWindow(forChannel channel: Channel) -> ChannelWindow {
        // Create channel window.
        let channelWindow = ChannelWindow(channel: channel)

        // Set workspace window as delegate.
        channelWindow.channelDelegate = self
        
        // Get initial channel window size.
        let initialSize = channelWindow.getSizeForCurrentState()
        
        // Create channel view controller and attach to window.
        let channelController = ChannelViewController(
            channel: channel,
            initialFrame: NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height)
        )
        
        // Set ChannelViewController as primary content view controller for channel window.
        channelWindow.contentViewController = channelController

        // Bind channel window events to controller.
        channelWindow.bind(.title, to: channelController, withKeyPath: "title", options: nil)
 
        // Make each channel view the first responder inside the window.
        channelWindow.makeFirstResponder(channelController.view)

        return channelWindow
    }
    
    // Add all channel windows as child windows.
    private func addChannelWindows() {
        for channel in channels {
            if let channelWindow = channelsMap[channel.id] {
                addChildWindow(channelWindow, ordered: NSWindow.OrderingMode.above)
            }
        }
    }
    
    // Move existing child window to front of other child windows
    private func moveChildWindowToFront(_ win: NSWindow) {
        removeChildWindow(win)
        addChildWindow(win, ordered: NSWindow.OrderingMode.above)
    }
    
    // Set initial size and position of each channel.
    private func setInitialChannelSizesAndPositions() {
        var specs = [(ChannelWindow, NSSize, NSPoint)]()
        var size: NSSize
        var position: NSPoint
        
        // First calculate updates across all channels.
        for (i, channelWindow) in getOrderedChannelWindows().enumerated() {
            // Calculate channel size.
            size = channelWindow.getSizeForCurrentState()
            
            // Calculate channel position.
            position = NSPoint(
                x: getChannelXPosition(forChannelSize: size),
                y: getInitialChannelYPosition(channelWindow: channelWindow, atIndex: i)
            )
            
            // Add updates to list.
            specs.append((channelWindow, size, position))
        }
        
        // Apply all updates.
        for (channelWindow, size, position) in specs {
            channelWindow.render(size: size, position: position)
        }
    }
    
    // Get x-position of channel window for its given size.
    private func getChannelXPosition(forChannelSize size: NSSize) -> CGFloat {
        CGFloat(ChannelsStyle.rightEdge) - size.width
    }
    
    // Get the initial y-position of the channel window at the provided index.
    private func getInitialChannelYPosition(channelWindow: ChannelWindow, atIndex index: Int) -> CGFloat {
        // Get the idle channel window height + any configured gutter spacing between channels.
        let heightWithGutter = Float(channelWindow.getIdleWindowSize().height) + ChannelsStyle.gutterSpacing
        
        // Calculate the absolute position of this channels window.
        return CGFloat(Float(Screen.getHeight()) - ChannelsStyle.topOffset - (heightWithGutter * Float(index)))
    }

    // Update size and position of each channel.
    private func updateChannelSizesAndPositions(activeChannelId: String) {
        // Get the active channel window's size change due to its latest state change.
        let (activeWindow, activeHeightOffset, _) = getActiveChannelSizeChange(activeChannelId: activeChannelId)

        // Only proceed if the active channel window and its height offset were successfully found.
        guard let activeChannelWindow = activeWindow, let activeChannelHeightOffset = activeHeightOffset else {
            return
        }

        // Get ordered list of existing channel windows.
        let channelWindows = getOrderedChannelWindows()
        
        // Find the index of the active channel window.
        let activeIndex = channelWindows.firstIndex{ $0 === activeChannelWindow }
        let activeChannelIndex = activeIndex!
                
        // Calculate new size and position destinations for all channel windows.
        calculateChannelWindowDestinations(
            channelWindows: channelWindows,
            activeChannelIndex: activeChannelIndex,
            activeChannelHeightOffset: activeChannelHeightOffset
        )
        
        // Animate each channel window to its new destination.
        animateChannelWindowsToDestinations(
            channelWindows: channelWindows,
            activeChannelIndex: activeChannelIndex
        )
        
        // If active channel's new state is previewing, ensure it is the only channel window in a previewing state.
        if activeChannelWindow.isPreviewing() {
            unpreviewNonActiveChannelWindows(channelWindows: channelWindows, activeChannelIndex: activeChannelIndex)
            
            // Add a timer to check the mouse position in relation to the active channel window, and force
            // it out of the previewing state if the mouse isn't inside of the active channel window anymore.
            activeChannelWindow.startPreviewingTimer()
        }
    }
        
    // Determine how much (if any) the active channel window will change due to its latest state change.
    private func getActiveChannelSizeChange(activeChannelId: String) -> (ChannelWindow?, Float?, Float?) {
        // Get active channel window (the window that triggered the update).
        guard let activeChannelWindow = channelsMap[activeChannelId] else {
            logger.error("Unable to find active window that triggered size update...")
            return (nil, nil, nil)
        }
        
        // Get the size offsets due to the active channel window's size change.
        let (activeChannelHeightOffset, activeChannelWidthOffset) = activeChannelWindow.getStateChangeSizeOffset()
        
        // Return active channel window with its size offset parameters.
        return (activeChannelWindow, activeChannelHeightOffset, activeChannelWidthOffset)
    }

    // Get an array of channel windows, top-to-bottom.
    private func getOrderedChannelWindows() -> [ChannelWindow] {
        var channelWindows = [ChannelWindow]()
                
        // Create an array of all workspace channels with existing windows, top-to-bottom.
        for channel in channels {
            guard let channelWindow = channelsMap[channel.id] else {
                continue
            }
            
            channelWindows.append(channelWindow)
        }
        
        return channelWindows
    }
    
    // Calculate new animation destinations for each channel window.
    private func calculateChannelWindowDestinations(
        channelWindows: [ChannelWindow],
        activeChannelIndex: Int,
        activeChannelHeightOffset: Float) {
        
        var channelWindow: ChannelWindow
        var newSize: NSSize
        var newPosition: NSPoint
        var destination: NSPoint
        
        // Calculate new size and position of all channel windows.
        for i in 0..<channelWindows.count {
            channelWindow = channelWindows[i]
            
            // Get current animation destination of channel.
            destination = channelWindow.getDestination()
            
            // Get size of channel window for its current state.
            newSize = channelWindow.getSizeForCurrentState()
            
            // Calculate new channel window position.
            newPosition = NSPoint(
                x: getChannelXPosition(forChannelSize: newSize),
                y: CGFloat(Float(destination.y) + (i < activeChannelIndex ? -activeChannelHeightOffset : activeChannelHeightOffset))
            )
            
            // Set newly calculated destination on channel window, itself.
            channelWindow.setDestination(newPosition)
        }
    }

    // Animate each channel window to its stored destination.
    private func animateChannelWindowsToDestinations(channelWindows: [ChannelWindow], activeChannelIndex: Int) {
        // Get active channel window and id.
        let activeChannelWindow = channelWindows[activeChannelIndex]
        let activeChannelId = activeChannelWindow.channel.id
        
        // Check to see if active channel window should animate its frame.
        let activeChannelWindowAnimatesFrame = ChannelWindow.stateShouldAnimateFrame(activeChannelWindow.state)
        
        // Check to see if active channel window should disable those around it.
        let activeChannelWindowDisablesOthers = ChannelWindow.stateShouldDisableOtherChannels(activeChannelWindow.state)
        
        NSAnimationContext.runAnimationGroup({ context in
            // Configure animation attributes.
            context.duration = AnimationConfig.ChannelWindows.duration
            context.timingFunction = CAMediaTimingFunction(name: AnimationConfig.ChannelWindows.timingFunctionName)
            context.allowsImplicitAnimation = true

            // Vars for loop below.
            var isActiveChannel, isDisabled, ignoreFrameUpdate: Bool

            // Re-render each channel window to its new destination.
            for (i, channelWindow) in channelWindows.enumerated() {
                isActiveChannel = i == activeChannelIndex
                isDisabled = !isActiveChannel && activeChannelWindowDisablesOthers
                ignoreFrameUpdate = isActiveChannel && !activeChannelWindowAnimatesFrame

                channelWindow.render(
                    size: ignoreFrameUpdate ? nil : channelWindow.getSizeForCurrentState(),
                    position: ignoreFrameUpdate ? nil : channelWindow.getDestination(),
                    isDisabled: isDisabled,
                    propagate: true,
                    animate: true
                )
            }
        }, completionHandler: { [weak self] in
            self?.onChannelWindowAnimationsComplete(activeChannelId: activeChannelId)
        })
    }
    
    private func onChannelWindowAnimationsComplete(activeChannelId: String) {
        // Get active channel window.
        guard let activeChannelWindow = channelsMap[activeChannelId] else {
            logger.error("Unable to find active channel window for id \(activeChannelId)...")
            return
        }

        // If the recording is waiting to be started...
        if activeChannelWindow.state === .recording(.starting) {
            // Move active window to front of other channels.
            moveChildWindowToFront(activeChannelWindow)
                    
            // Start a new recording.
            activeChannelWindow.startRecording()
        }
    }
    
    // Force a "mouse-exited" event on any previewing channel windows that aren't the active channel window.
    private func unpreviewNonActiveChannelWindows(channelWindows: [ChannelWindow], activeChannelIndex: Int) {
        for (i, channelWindow) in channelWindows.enumerated() {
            if i == activeChannelIndex {
                continue
            }
            
            // If a channel that isn't the active channel is found to be in
            // the previewing state, force it out of this state.
            if channelWindow.isPreviewing() {
                channelWindow.registerMouseExited()
            }
        }
    }
    
    // Error view.
    private func renderError(_ error: Error) {
        // TODO
    }

    // Loading view.
    private func renderLoading() {
        // TODO
    }
    
    // No workspaces exist yet view.
    private func renderCreateFirstWorkspace() {
        // TODO
    }
    
    // No channels exist yet in the current workspace.
    private func renderCreateFirstChannel() {
        // TODO
    }
    
    // Render all workspace channels on screen in separate windows.
    private func renderChannels() {
        // Clear out channels map.
        channelsMap.removeAll()
        
        // Render a separate view if no channels exist yet.
        if channels.isEmpty {
            renderCreateFirstChannel()
            return
        }
        
        // Create each channel window and add them to the channelsMap.
        for channel in channels {
            channelsMap[channel.id] = createChannelWindow(forChannel: channel)
        }
        
        // Size and position channel windows.
        setInitialChannelSizesAndPositions()

        // Add all channel windows as child windows.
        addChannelWindows()
    }

    // Loaded view.
    private func renderLoaded() {
        // Render all channels of workspace.
        renderChannels()
    }
            
    // Render workspace window contents based on current state.
    func render(_ state: WorkspaceState) {
        switch state {
        // Loading current workspace.
        case .loading:
            renderLoading()
            
        // No workspaces exist yet.
        case .noWorkspacesExist:
            renderCreateFirstWorkspace()
            
        // Workspace successfully loaded.
        case .loaded:
            renderLoaded()
        
        // Loading workspace failed.
        case .failed(let error):
            renderError(error)
        }
    }
}
