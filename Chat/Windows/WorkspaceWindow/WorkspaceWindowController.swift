//
//  WorkspaceWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa
import Combine

// Controller for workspace window.
class WorkspaceWindowController: NSWindowController, NSWindowDelegate, WorkspaceKeyManagerDelegate {
            
    // Manages state and data for workspace window.
    private var windowModel: WorkspaceWindowModel!
        
    // Unique channel window controllers mapped by channel id.
    private var channelWindowControllers = [String: ChannelWindowController]()

    // Workspace state subscription.
    private var stateSubscription: AnyCancellable?
    
    // Channel state subscriptions.
    private var channelStateSubscriptions = [String: AnyCancellable?]()
    
    // Manages all global hot-keys and their events.
    private var keyManager: WorkspaceKeyManager!
    
    // Bool to determine whether channels have been rendered at least once.
    private var channelsHaveRendered = false
    
    // Id of most-recent active channel.
    private var activeChannelId: String? {
        didSet { promotePreviousChannelStates() }
    }

    // Proper init to call when creating this class.
    convenience init() {
        self.init(window: nil)
    }
    
    // Override delegated init.
    private override init(window: NSWindow?) {
        precondition(window == nil, "call init() with no window")
        
        // Initialize with new workspace window.
        super.init(window: WorkspaceWindow())
        
        // Assign self as new workspace window's delegate.
        self.window!.delegate = self
        
        // Create window model.
        windowModel = WorkspaceWindowModel()
        
        // Configure window model subscription.
        subscribeToWindowModel()
        
        // Create global hot-key manager.
        createKeyManager()

        // Configure app permissions needed in this window.
        configureAppPermissions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Load the current workspace.
    func loadCurrentWorkspace() {
        windowModel.loadWorkspace()
    }

    // Toggle the key listeners associated with recordings.
    func toggleRecordingKeyListeners(enable: Bool) {
        keyManager.toggleKeyListener(forKey: .escKey, pause: !enable)
        keyManager.toggleKeyListener(forKey: .returnKey, pause: !enable)
    }

    // Handle escape button key-down event.
    func onEscPress() {
        findAndCancelActiveRecording()
    }
    
    // Handle return button key-down event.
    func onReturnPress() {
        findAndSendActiveRecording()
    }
    
    // Handle command button key-down event.
    func onCommandKeyDown() {
        startChannelPromptSpeechRecognizer()
    }
    
    // Handle command button key-up event.
    func onCommandKeyUp() {
        stopSpeechRecognition()
    }
        
    // Handler called whenever a channel updates state.
    private func onChannelStateUpdate(channelId: String) {
        // Only proceed if channel window controller exists and it's state case changed.
        guard let channelWindowController = channelWindowControllers[channelId],
              channelWindowController.stateChangedCase() else {
            return
        }
        
        // Set this channel to the active one.
        activeChannelId = channelId
        
        // Re-render current state.
        render(windowModel.state)
    }
    
    // Called when channel rendering has completed.
    private func onChannelsRendered() {
        
    }
    
    // Subscribe to window state changes.
    private func subscribeToWindowModel() {
        // Render any time window state changes.
        stateSubscription = windowModel.$state.sink { [weak self] state in
            self?.render(state)
        }
    }
    
    // Seek permissions this app requries within this window.
    private func configureAppPermissions() {
        // Seek audio and video-related permissions.
        AV.seekPermissions()
    }
    
    // Create manager for for all global hot-keys associated with workspace window.
    private func createKeyManager() {
        // Create workspace key manager.
        keyManager = WorkspaceKeyManager()
        
        // Set self as key manager delegate.
        keyManager.delegate = self
        
        // Turn off all recording key listeners to start.
        toggleRecordingKeyListeners(enable: false)
    }
    
    // Promote previous state to current state for all non-active channels.
    private func promotePreviousChannelStates() {
        for (channelId, channelWindowController) in channelWindowControllers where channelId != activeChannelId {
            channelWindowController.promotePreviousState()
        }
    }
    
    private func stopSpeechRecognition() {
//        AV.mic.stopSpeechRecognition()
    }
    
    private func startChannelPromptSpeechRecognizer() {
//        AV.mic.startChannelPromptAnalyzer(onChannelPrompted: { [weak self] result in
//            if let channelId = result as? String {
//                self?.onChannelPromptedBySpeech(channelId: channelId)
//            }
//        })
    }
    
//    private func onChannelPromptedBySpeech(channelId: String) {
//        // Get ordered list of existing channel windows.
//        let channelWindows = getOrderedChannelWindows()
//
//        // Find the index of the active channel window.
//        let activeIndex = channelWindows.firstIndex{ $0.channel.id == channelId }
//
//        // Ensure channel window index was found.
//        guard let activeChannelIndex = activeIndex else {
//            logger.error("Speech recognizer prompted channel that couldn't be found: \(channelId)")
//            return
//        }
//
//        // Switch any channel windows currently in the previewing state to back to idle.
//        unpreviewNonActiveChannelWindows(
//            channelWindows: channelWindows,
//            activeChannelIndex: activeChannelIndex
//        )
//
//        // Get the active window by index.
//        let activeChannelWindow = channelWindows[activeChannelIndex]
//
//        // Trigger channel window speech prompted handler.
//        activeChannelWindow.onSpeechPrompted()
//    }
    
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
        return CGFloat(Float(Screen.getHeight()) - WorkspaceWindow.Style.channelCeiling - (heightWithGutter * Float(index)))
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
        guard let activeChannelWindow = channelWindowRefs[activeChannelId] else {
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
        for channel in windowModel.channels {
            guard let channelWindow = channelWindowRefs[channel.id] else {
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
        guard let activeChannelWindow = channelWindowRefs[activeChannelId] else {
            logger.error("Unable to find active channel window for id \(activeChannelId)...")
            return
        }

        // If the recording is waiting to be started...
        if activeChannelWindow.state === .recording(.starting) {
            // Move active window to front of other channels.
            bringChannelWindowToFront(activeChannelWindow)
                    
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
    
    
    
    
    
    
    
    
    
    
    
    
    // Add channel window as a child window to workspace window.
    private func addChannelWindow(forController controller: ChannelWindowController) {
        window!.addChildWindow(controller.window!, ordered: NSWindow.OrderingMode.above)
    }
    
    // Remove channel window as a child window from workspace window.
    private func removeChannelWindow(forController controller: ChannelWindowController) {
        window!.removeChildWindow(controller.window!)
    }

    // Add channel window as a child window to workspace window.
    private func bringChannelWindowToFront(forController controller: ChannelWindowController) {
        removeChannelWindow(forController: controller)
        addChannelWindow(forController: controller)
    }
    
    private func createChannelWindowController(forChannel channel: Channel) -> ChannelWindowController {
        // Create channel window controller.
        let channelWindowController = ChannelWindowController(channel: channel)
        
        // Subscribe to channel state updates.
        channelStateSubscriptions[channel.id] = channelWindowController.$state.sink { [weak self] state in
            self?.onChannelStateUpdate(channelId: channel.id)
        }
        
        return channelWindowController
    }
    
    // Upsert channel window controller for channel id.
    private func upsertChannelWindowController(forChannel channel: Channel) -> (Bool, ChannelWindowController) {
        var isNew = false
        
        // Get channel window controller by channel id, or create new one if doesn't exist.
        guard let channelWindowController = channelWindowControllers[channel.id] else {
            channelWindowControllers[channel.id] = createChannelWindowController(forChannel: channel)
            isNew = true
        }
        
        return (isNew, channelWindowController)
    }
    
    private func shouldDisableChannel() -> Bool {
        
    }
    
    private func getChannelSize() -> NSSize {
        
    }
    
    private func getChannelPosition() -> NSPoint {
        
    }
    
    private func getChannelRenderSpec(for channel: Channel) -> (ChannelWindowController, ChannelRenderSpec) {
        let (isNew, channelWindowController) = upsertChannelWindowController(forChannel: channel)
        
        // Create new spec to render channel window with.
        let spec = ChannelRenderSpec(
            isNew: isNew,
            isDisabled: shouldDisableChannel(),
            size: getChannelSize(),
            position: getChannelPosition()
        )
        
        return (channelWindowController, spec)
    }
        
    // Error view.
    private func renderError(_ error: Error) {
        print("render error: \(error)")
    }

    // Loading view.
    private func renderLoading() {
        
    }
    
    // No workspaces exist yet view.
    private func renderCreateFirstWorkspace() {
        
    }
    
    // No channels exist yet in the current workspace.
    private func renderCreateFirstChannel() {
        // TODO
    }
    
    // Render all channel windows.
    private func renderChannels(_ channels: [Channel]) {
        // Iterate over a newly calculated render spec for each channel.
        for (channelWindowController, spec) in channels.map(getChannelRenderSpec) {
            // If channel is new, add the channel window as a child window before rendering.
            if spec.isNew {
                addChannelWindow(forController: channelWindowController)
            }
            
            // Render channel window.
            channelWindowController.render(spec)
        }
    }
    
    // Render all channel windows (with optional animation).
    private func renderChannels(_ channels: [Channel], withAnimation: Bool) {
        // Render without animation if specified.
        guard withAnimation else {
            renderChannels(channels)
            onChannelsRendered()
            return
        }
        
        // Render channels with animation.
        NSAnimationContext.runAnimationGroup({ [weak self] context in
            // Configure animation attributes.
            context.duration = ChannelWindow.AnimationConfig.duration
            context.timingFunction = CAMediaTimingFunction(name: ChannelWindow.AnimationConfig.timingFunctionName)
            context.allowsImplicitAnimation = true
            
            // Render channels.
            self?.renderChannels(channels)
            
        }, completionHandler: { [weak self] in
            self?.onChannelsRendered()
        })
    }
    
    // Render current workspace.
    private func renderWorkspace(_ workspace: Workspace) {
        let channels = workspace.channels
        
        // If no channels exist yet, render view to create first channel.
        if channels.isEmpty {
            renderCreateFirstChannel()
            return
        }
        
        // Render channels and animate the changes if this isn't the first time rendering.
        renderChannels(channels, withAnimation: channelsHaveRendered)
        
        // Note that channels have been rendered at least once.
        channelsHaveRendered = true
    }

    // Loaded view.
    private func renderLoaded(workspace: Workspace?) {
        if let ws = workspace {
            renderWorkspace(ws)
        } else {
            renderCreateFirstWorkspace()
        }
    }

    // Render workspace window contents based on current state.
    func render(_ state: WorkspaceWindowModel.State) {
        switch state {
        // Loading current workspace.
        case .loading:
            renderLoading()

        // Workspace successfully loaded.
        case .loaded(let workspace):
            renderLoaded(workspace: workspace)
        
        // Loading workspace failed.
        case .failed(let error):
            renderError(error)
        }
    }
}
