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
    func onEscDown() {
        findAndCancelActiveRecording()
    }
    
    // Handle return button key-down event.
    func onReturnDown() {
        findAndSendActiveRecording()
    }
    
    // Handle command button key-down event.
    func onCommandDown() {}

    // Handle command button key-up event.
    func onCommandUp() {}
        
    // Handler called whenever a channel updates state.
    private func onChannelStateUpdate(channelId: String) {
        // Get active channel window controller for channel id.
        guard let activeChannelWindowController = channelWindowControllers[channelId] else {
            return
        }
        
        // If not switching to actively previewing, canel the previewing timer.
        if !activeChannelWindowController.isPreviewing() {
            activeChannelWindowController.cancelPreviewingTimer()
        }
        
        // Re-render ONLY the active channel if it should be updated individually.
        if activeChannelWindowController.shouldRenderIndividually() {
            activeChannelWindowController.renderFromState()
            return
        }
        
        // Promote previous state to current state for all non-active channels.
        promotePreviousChannelStates(activeChannelId: channelId)
        
        // Re-render the entire workspace with all channels.
        render(windowModel.state, activeChannelId: channelId)
    }
    
    // Called when channel rendering has completed.
    private func onChannelsRendered(activeChannelId: String) {
        checkIfActiveRecordingNeedsStart(activeChannelId: activeChannelId)
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
    private func promotePreviousChannelStates(activeChannelId: String) {
        for (channelId, channelWindowController) in channelWindowControllers where channelId != activeChannelId {
            channelWindowController.promotePreviousState()
        }
    }
    
    // Cancel the active recording if one exists.
    private func findAndCancelActiveRecording() {
        if let controller = findActiveRecordingChannelWindowController() {
            controller.cancelRecording()
        }
    }
    
    // Send the active recording if one exists.
    private func findAndSendActiveRecording() {
        if let controller = findActiveRecordingChannelWindowController() {
            controller.sendRecording()
        }
    }
    
    // Find the first channel with a recording state.
    private func findActiveRecordingChannelWindowController() -> ChannelWindowController? {
        guard let channels = windowModel.workspace?.channels else {
            return nil
        }
        
        return getChannelWindowControllers(forChannels: channels).first(where: { $0.isRecording() })
    }

    private func checkIfActiveRecordingNeedsStart(activeChannelId: String) {
        // Ensure active channel has a recording waiting to be started.
        guard let activeChannelWindowController = channelWindowControllers[activeChannelId],
              activeChannelWindowController.isRecordingInitializing() else {
            return
        }
    
        // Move active window to front of other channels.
        bringChannelWindowToFront(forController: activeChannelWindowController)

        // Start the recording.
        activeChannelWindowController.startRecording()
    }
    
    private func unpreviewNonActiveChannels(channels: [Channel], activeChannelIndex: Int) {
        for (i, channel) in channels.enumerated() {
            if i == activeChannelIndex {
                continue
            }
            
            if let channelWindowController = channelWindowControllers[channel.id], channelWindowController.isPreviewing() {
                channelWindowController.forceMouseExit()
            }
        }
    }
    
    private func limitPreviewingChannelsToOne(channels: [Channel], activeChannelId: String) {
        // Get active channel window controller and its index.
        let (activeChannelIndex, controller) = getActiveChannelWindowController(
            inChannels: channels,
            activeChannelId: activeChannelId
        )
        
        // Ensure active channel window controller exists and is previewing.
        guard let activeChannelWindowController = controller, activeChannelWindowController.isPreviewing() else {
            return
        }
        
        // Force a "mouse-exited" event on any previewing non-active channels.
        unpreviewNonActiveChannels(channels: channels, activeChannelIndex: activeChannelIndex)
        
        // Start the active channel's previewing timer.
        activeChannelWindowController.startPreviewingTimer()
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
    
    private func createChannelWindowController(forChannel channel: Channel, atIndex index: Int) -> ChannelWindowController {
        // Create channel window controller.
        let channelWindowController = ChannelWindowController(channel: channel)
        
        // Add self as weak reference.
        channelWindowController.workspaceWindowController = self
        
        // Build a render spec for the initial rendering of the channel.
        var channelRenderSpec = ChannelRenderSpec()
        
        // Initial size.
        channelRenderSpec.size = channelWindowController.size
        
        // Initial position.
        channelRenderSpec.position = NSPoint(
            x: getChannelWindowXPosition(windowWidth: channelRenderSpec.size.width),
            y: getChannelWindowInitialYPosition(forIndex: index)
        )

        // Perform initial render of channel.
        channelWindowController.render(channelRenderSpec)
        
        // Subscribe to channel state updates.
        channelStateSubscriptions[channel.id] = channelWindowController.$publishedState.sink { [weak self] state in
            self?.onChannelStateUpdate(channelId: channel.id)
        }
        
        return channelWindowController
    }
    
    // Upsert channel window controller for channel id.
    private func upsertChannelWindowController(forChannel channel: Channel, atIndex index: Int) -> (ChannelWindowController, Bool) {
        if let channelWindowController = channelWindowControllers[channel.id] {
            return (channelWindowController, false)
        }
        
        let channelWindowController = createChannelWindowController(forChannel: channel, atIndex: index)
        
        channelWindowControllers[channel.id] = channelWindowController
        
        return (channelWindowController, true)
    }
    
    // Analyze properties of active channel.
    private func analyzeActiveChannel(channels: [Channel], activeChannelId: String) -> (Int, Float, Bool) {
        // Get active channel window controller and its index.
        let (index, activeChannelWindowController) = getActiveChannelWindowController(
            inChannels: channels,
            activeChannelId: activeChannelId
        )
        
        // Extract optional.
        guard let channelWindowController = activeChannelWindowController else {
            return (0, 0, false)
        }
        
        return (
            index,
            channelWindowController.latestHeightOffset,
            channelWindowController.disablesAdjacentChannels
        )
    }
    
    // Find the active window controller and its index in the given list of channels.
    private func getActiveChannelWindowController(inChannels channels: [Channel], activeChannelId: String) -> (Int, ChannelWindowController?) {
        for (i, channel) in channels.enumerated() {
            if channel.id == activeChannelId, let channelWindowController = channelWindowControllers[channel.id] {
                return (i, channelWindowController)
            }
        }

        return (0, nil)
    }
    
    private func getChannelWindowControllers(forChannels channels: [Channel]) -> [ChannelWindowController] {
        channels.compactMap({ channelWindowControllers[$0.id] })
    }
    
    private func getChannelWindowXPosition(windowWidth: CGFloat) -> CGFloat {
        CGFloat(WorkspaceWindow.Style.rightEdge) - windowWidth
    }

    // Get the initial y-position of the channel window at the provided index.
    private func getChannelWindowInitialYPosition(forIndex index: Int) -> CGFloat {
        // Get the idle channel window height + any configured gutter spacing between channels.
        let heightWithGutter = Float(ChannelWindow.Style.idleSize.height) + WorkspaceWindow.Style.channelGutterSpacing

        // Calculate the absolute position of this channels window.
        return CGFloat(Float(Screen.getHeight()) - WorkspaceWindow.Style.channelCeiling - (heightWithGutter * Float(index)))
    }

    private func getChannelWindowNewYPosition(
        forController channelWindowController: ChannelWindowController,
        atIndex index: Int,
        activeChannelIndex: Int,
        activeChannelHeightOffset: Float) -> CGFloat {

        CGFloat(channelWindowController.getDestination().y) + CGFloat(
            index < activeChannelIndex ? -activeChannelHeightOffset : activeChannelHeightOffset
        )
    }

    private func getChannelAppearance(
        forController channelWindowController: ChannelWindowController,
        atIndex index: Int,
        activeChannelIndex: Int,
        activeChannelHeightOffset: Float) -> NSRect {
        
        // Create new appearance.
        var appearance = NSRect()
        
        // New size should already be represented by current channel state.
        appearance.size = channelWindowController.size
                
        // Calculate new channel window position.
        appearance.origin = NSPoint(
            x: getChannelWindowXPosition(windowWidth: appearance.size.width),
            y: getChannelWindowNewYPosition(
                forController: channelWindowController,
                atIndex: index,
                activeChannelIndex: activeChannelIndex,
                activeChannelHeightOffset: activeChannelHeightOffset
            )
        )

        return appearance
    }
    
    private func getChannelRenderSpec(
        forChannel channel: Channel,
        atIndex index: Int,
        activeChannelIndex: Int,
        activeChannelHeightOffset: Float,
        isDisabled: Bool) -> (ChannelWindowController, ChannelRenderSpec) {
        
        // Upsert channel window controller.
        let (channelWindowController, isNew) = upsertChannelWindowController(forChannel: channel, atIndex: index)

        // Get channel's appearance.
        let appearance = getChannelAppearance(
            forController: channelWindowController,
            atIndex: index,
            activeChannelIndex: activeChannelIndex,
            activeChannelHeightOffset: activeChannelHeightOffset
        )
        
        // Set new position destination on channel window controller.
        channelWindowController.setDestination(appearance.origin)
        
        // Create new spec to render channel window with.
        let spec = ChannelRenderSpec(
            isNew: isNew,
            isDisabled: isDisabled,
            size: appearance.size,
            position: appearance.origin
        )
        
        // Return controller with spec.
        return (channelWindowController, spec)
    }
    
    private func getChannelRenderSpecs(channels: [Channel], activeChannelId: String) -> [(ChannelWindowController, ChannelRenderSpec)] {
        // Get active channel window index and height offset due to latest state change.
        let (activeIndex, activeHeightOffset, disableNonActiveChannels) = analyzeActiveChannel(
            channels: channels,
            activeChannelId: activeChannelId
        )
        
        // Return list of channel render specs with their associated controllers.
        return channels.enumerated().map { (i, channel) in
            getChannelRenderSpec(
                forChannel: channel,
                atIndex: i,
                activeChannelIndex: activeIndex,
                activeChannelHeightOffset: activeHeightOffset,
                isDisabled: disableNonActiveChannels && i != activeIndex
            )
        }
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
    private func renderChannelWindows(forSpecs specs: [(ChannelWindowController, ChannelRenderSpec)]) {
        for (channelWindowController, spec) in specs {
            // If channel is new, add the channel window as a child window before rendering.
            if spec.isNew {
                addChannelWindow(forController: channelWindowController)
            }
            
            // Render channel window.
            channelWindowController.render(spec)
        }
    }
    
    // Render all channel windows (with optional animation).
    private func renderChannels(_ channels: [Channel], activeChannelId: String, withAnimation: Bool) {
        // Get list of channel render specs.
        let channelRenderSpecs = getChannelRenderSpecs(channels: channels, activeChannelId: activeChannelId)
        
        // Don't render with animation unless specified.
        guard withAnimation else {
            renderChannelWindows(forSpecs: channelRenderSpecs)
            onChannelsRendered(activeChannelId: activeChannelId)
            return
        }
        
        // Render channels with animation.
        NSAnimationContext.runAnimationGroup({ [weak self] context in
            // Configure animation attributes.
            context.duration = ChannelWindow.AnimationConfig.duration
            context.timingFunction = CAMediaTimingFunction(name: ChannelWindow.AnimationConfig.timingFunctionName)
            context.allowsImplicitAnimation = true
            
            // Render channel windows.
            self?.renderChannelWindows(forSpecs: channelRenderSpecs)
            
        }, completionHandler: { [weak self] in
            self?.onChannelsRendered(activeChannelId: activeChannelId)
        })
    }
    
    // Render current workspace.
    private func renderWorkspace(_ workspace: Workspace, activeChannelId: String? = nil) {
        let channels = workspace.channels
        
        // If no channels exist yet, render view to create first channel.
        if channels.isEmpty {
            renderCreateFirstChannel()
            return
        }
        
        // Give active channel id a fallback of the first channel's id.
        let activeId = activeChannelId ?? channels[0].id
        
        // Render channels and animate the changes if this isn't the first time rendering.
        renderChannels(channels, activeChannelId: activeId, withAnimation: channelsHaveRendered)
        
        // Note that channels have been rendered at least once.
        channelsHaveRendered = true
        
        // Ensure only 1 channel is ever in the previewing state at a time.
        limitPreviewingChannelsToOne(channels: channels, activeChannelId: activeId)
    }

    // Loaded view.
    private func renderLoaded(workspace: Workspace?, activeChannelId: String? = nil) {
        if let ws = workspace {
            renderWorkspace(ws, activeChannelId: activeChannelId)
        } else {
            renderCreateFirstWorkspace()
        }
    }

    // Render workspace window contents based on current state.
    func render(_ state: WorkspaceWindowModel.State, activeChannelId: String? = nil) {
        switch state {
        case .loading:
            renderLoading()
        case .loaded(let workspace):
            renderLoaded(workspace: workspace, activeChannelId: activeChannelId)
        case .failed(let error):
            renderError(error)
        }
    }
}
