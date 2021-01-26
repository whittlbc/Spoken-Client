//
//  ChannelAvatarViewController.swift
//  Chat
//
//  Created by Ben Whittle on 12/27/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa
import Combine
import AVFoundation

// Controller for ChannelAvatarView to manage all of its subviews and their interactions.
class ChannelAvatarViewController: NSViewController {
    
    // Manages data for avatar view.
    private var viewModel: ChannelAvatarViewModel!
    
    // Channel avatar view.
    private var avatarView: ChannelAvatarView { view as! ChannelAvatarView }
    
    // Container view of avatar.
    private var containerView: RoundShadowView!
    
    // View with image content.
    private var imageView: RoundView!
    
    // New recording indicator icon.
    private var newRecordingIndicator: RoundShadowView?

    // Blur layer to fade-in when channel is disabled.
    private var blurLayer: CALayer?
    
    // Spinner view around avatar to show when sending arbitrary content.
    private var spinnerView: ChasingTailSpinnerView?
    
    // Self-drawn checkmark view to show when a recording is sent.
    private var checkmarkView: SelfDrawnCheckmarkView?
    
    // Avatar image subscription.
    private var imageSubscription: AnyCancellable?
    
    // Channel video preview layer.
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    // Subscription to av recorder state changes.
    private var avRecorderSubscription: AnyCancellable?

    // Loader view to show around avatar when loading arbitrary content.
    private var loaderView: DashSpinnerView?

    // Proper initializer to use when rendering channel.
    convenience init(channel: Channel) {
        self.init(nibName: nil, bundle: nil)
        
        // Create view model.
        viewModel = ChannelAvatarViewModel(channel: channel)
    }
    
    // Override delegated init.
    private override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Use ChannelView as primary view for this controller.
    override func loadView() {
        view = ChannelAvatarView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make view layer-based.
        setupViewLayer()
    
        // Add container to avatar.
        addContainerView()

        // Add avatar image view.
        addImageView()
        
        // Subscribe to view model.
        subscribeToViewModel()
        
        // Load and set avatar image.
        loadAvatarImage()
        
        // Subscribe to AV recorder.
        subscribeToAVRecorder()
    }
    
    // Handle changes in channel disability.
    func isDisabledChanged(to isDisabled: Bool) {
        // Toggle image view blur based on isDisabled status.
        animateImageViewBlur(
            showBlur: isDisabled,
            blurRadius: ChannelAvatarView.Style.BlurLayer.disabledBlurRadius,
            duration: ChannelAvatarView.AnimationConfig.BlurLayer.duration
        )
    }
    
    // Fetch avatar image from view model.
    private func loadAvatarImage() {
        viewModel.loadImage()
    }
    
    // Subscribe to view model image changes.
    private func subscribeToViewModel() {
        // Set avatar image any time it changes.
        imageSubscription = viewModel.$image.sink { [weak self] image in
            self?.setAvatarImage(to: image)
        }
    }
    
    private func subscribeToAVRecorder() {
        avRecorderSubscription = AV.avRecorder.$state.sink { [weak self] state in
            self?.onAVRecorderStateChange(state: state)
        }
    }
    
    private func onAVRecorderStateChange(state: AVRecorderState) {
        switch state {
        
        // Just starting recording.
        case .starting(let session, let channelId):
            guard channelId == viewModel.channel.id else {
                return
            }
                        
            self.addVideoPreviewLayer(session: session)
        
        // Recording started and visible.
        case .started(let channelId):
            guard channelId == viewModel.channel.id else {
                return
            }
                        
            print("READY")

        // Stopping recording.
        case .stopping:
            self.removeVideoPreviewLayer()

        default:
            break
        }
    }
    
    // Make avatar view layer-based and allow for overflow.
    private func setupViewLayer() {
        view.wantsLayer = true
        view.layer?.masksToBounds = false
    }

    // Add and constrain container view.
    private func addContainerView() {
        // Create container view.
        createContainerView()
        
        // Constrain container view.
        constrainContainerView()
    }
    
    // // Add and constrain image view.
    private func addImageView() {
        // Create image view.
        self.createImageView()
        
        // Constrain image view.
        self.constrainImageView()
    }

    // Set image as contents of image view layer.
    private func setAvatarImage(to image: NSImage?) {
        imageView.layer?.contents = image
    }
    
    // Create new container view.
    private func createContainerView() {
        // Create new round view with with drop shadow.
        containerView = RoundShadowView(
            shadowConfig: ChannelAvatarView.Style.ContainerView.ShadowStyle.getShadow(forState: .idle)
        )

        // Make it layer based and allow for overflow so that shadow can be seen.
        containerView.wantsLayer = true
        containerView.layer?.masksToBounds = false
                
        // Add container view as subview..
        view.addSubview(containerView)
    }
    
    // Set up container view auto-layout.
    private func constrainContainerView() {
        // Set up auto-layout for sizing/positioning.
        containerView.translatesAutoresizingMaskIntoConstraints = false
                
        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set height of container.
            containerView.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                constant: ChannelAvatarView.Style.ContainerView.PositionStyle.heightOffset
            ),
            
            // Keep container height and width the same.
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
                        
            // Align right sides (but shift it left the specified amount).
            containerView.rightAnchor.constraint(
                equalTo: view.rightAnchor,
                constant: ChannelAvatarView.Style.ContainerView.PositionStyle.leftOffset
            ),
            
            // Align y-centers.
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // Create new image view.
    private func createImageView() {
        // Create new round view.
        imageView = RoundView()
                
        // Make it layer based and ensure overflow is hidden.
        imageView.wantsLayer = true
        imageView.layer?.masksToBounds = true

        // Add image to container.
        containerView.addSubview(imageView)
    }
    
    // Set up image view auto-layout.
    private func constrainImageView() {
        // Set up auto-layout for sizing/positioning.
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Fix image size to container size (equal height, width, and center).
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            imageView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
                
        // Constrain the image's size to the view's size.
        imageView.layer?.contentsGravity = .resizeAspectFill
        
        // Allow the image view to respond to filters added to it.
        imageView.layerUsesCoreImageFilters = true
    }
    
    // Create new recording indicator icon.
    private func createNewRecordingIndicator() -> RoundShadowView {
        // Create new round view with with drop shadow.
        let indicator = RoundShadowView(
            shadowConfig: ChannelAvatarView.Style.NewRecordingIndicator.ShadowStyle.grounded
        )
        
        // Make it layer based and start it as hidden.
        indicator.wantsLayer = true
        indicator.layer?.masksToBounds = false
        indicator.alphaValue = 0
        
        // Add indicator as subview above container view.
        view.addSubview(
            indicator,
            positioned: NSWindow.OrderingMode.above,
            relativeTo: containerView
        )
        
        // Add auto-layout constraints to indicator.
        constrainNewRecordingIndicator(indicator)

        // Set icon as the contents of the view.
        indicator.layer?.contents = Icon.plusCircle
        
        // Constrain the icon's image size to the view's size.
        indicator.layer?.contentsGravity = .resizeAspectFill

        // Assign new indicator to instance property.
        newRecordingIndicator = indicator
        
        // Return newly created, unwrapped, view.
        return newRecordingIndicator!
    }
    
    // Set up new-recording indicator auto-layout.
    private func constrainNewRecordingIndicator(_ indicator: RoundShadowView) {
        // Set up auto-layout for sizing/positioning.
        indicator.translatesAutoresizingMaskIntoConstraints = false

        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set height of indicator.
            indicator.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: ChannelAvatarView.Style.NewRecordingIndicator.PositionStyle.relativeHeight
            ),
            
            // Keep indicator height and width the same.
            indicator.widthAnchor.constraint(equalTo: indicator.heightAnchor),
            
            // Align right sides (but shift it left the specified amount).
            indicator.rightAnchor.constraint(
                equalTo: view.rightAnchor,
                constant: ChannelAvatarView.Style.NewRecordingIndicator.PositionStyle.edgeOffset
            ),
            
            // Align bottom sides (but shift it up the specified amount).
            indicator.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: ChannelAvatarView.Style.NewRecordingIndicator.PositionStyle.edgeOffset
            ),
        ])
    }
    
    // Create new blur layer and add it as a sublayer to image view.
    private func createBlurLayer() -> CALayer {
        // Create new layer the size of image view.
        let blur = CALayer()
        blur.frame = imageView.bounds
        blur.contentsGravity = .resizeAspectFill

        // Make it transparent and mask it.
        blur.backgroundColor = CGColor.clear
        blur.masksToBounds = true
        
        // Add a zero-value gaussian blur.
        if let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: 0]) {
            blur.backgroundFilters = [blurFilter]
        }
        
        // Assign new blur layer to instance property.
        blurLayer = blur
        
        // Add blur layer as sublayer to image view.
        imageView.layer?.addSublayer(blur)

        return blur
    }
        
    // Create spinner view to spin inside avatar during sending of content.
    private func createSpinnerView() -> ChasingTailSpinnerView {
        // Get size of image view frame.
        let imageSize = imageView.frame.size
        
        // Get spinner view diameter.
        let diameter = ChannelAvatarView.Style.SpinnerView.diameter
        
        // Create spinner frame in center of image view frame.
        let spinnerFrame = NSRect(
            x: (imageSize.width - diameter) / 2,
            y: (imageSize.height - diameter) / 2,
            width: diameter,
            height: diameter
        )
        
        // Create new chasing tail spinner.
        let spinner = ChasingTailSpinnerView(
            frame: spinnerFrame,
            color: ChannelAvatarView.Style.SpinnerView.color
        )
        
        // Add spinner as subview of container view.
        containerView.addSubview(
            spinner,
            positioned: NSWindow.OrderingMode.above,
            relativeTo: imageView
        )
        
        return spinner
    }
    
    // Create self-drawing checkmark view to show when recording is successfully sent.
    private func createCheckmarkView() -> SelfDrawnCheckmarkView {
        // Get size of image view frame.
        let imageSize = imageView.frame.size
        
        let length = ChannelAvatarView.Style.CheckmarkView.length
        
        // Create checkmark frame.
        let checkmarkFrame = NSRect(
            x: (imageSize.width - length) / 2,
            y: (imageSize.height - length) / 2,
            width: length,
            height: length
        )
        
        // Create new self-drawn checkmark view.
        let checkmark = SelfDrawnCheckmarkView(
            frame: checkmarkFrame,
            color: ChannelAvatarView.Style.CheckmarkView.color
        )
        
        // Add checkmark as subview of container view.
        containerView.addSubview(
            checkmark,
            positioned: NSWindow.OrderingMode.above,
            relativeTo: imageView
        )
        
        return checkmark
    }
    
    private func createVideoPreviewLayer(session: AVCaptureSession) -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        let diameter = (
            ChannelWindow.Style.recordingSize(withVideo: true).height +
            ChannelAvatarView.Style.ContainerView.PositionStyle.heightOffset
        )
                        
        previewLayer.frame = NSRect(x: 0, y: 0, width: diameter, height: diameter)
        
        previewLayer.videoGravity = .resizeAspectFill
        
        previewLayer.masksToBounds = true
        
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isVideoMirrored = true

        return previewLayer
    }
    
    // Create loader view to spin around avatar during the loading of arbitrary content.
    private func createLoaderView() -> DashSpinnerView {
        // Get size of image view frame.
        let imageSize = imageView.frame.size
        
        // Get loader view diameter.
        let diameter = ChannelAvatarView.Style.LoaderView.diameter
        
        // Create loader frame in center of image view frame.
        let loaderFrame = NSRect(
            x: (imageSize.width - diameter) / 2,
            y: (imageSize.height - diameter) / 2,
            width: diameter,
            height: diameter
        )
        
        // Create new dash spinner view as the loader view.
        let loader = DashSpinnerView(frame: loaderFrame)
        
        // Add loader as subview of container view.
        containerView.addSubview(
            loader,
            positioned: NSWindow.OrderingMode.above,
            relativeTo: imageView
        )
        
        return loader
    }
    
    // Animate the size change of avatar view for the given channel state.
    private func animateAvatarViewSize(toState state: ChannelState) {
        avatarView.animateSize(toDiameter: ChannelWindow.Style.size(forState: state).height)
    }
    
    // Toggle the amount of drop shadow for container view based on state.
    private func animateContainerViewShadow(toState state: ChannelState) {
        containerView.updateShadow(
            toConfig: ChannelAvatarView.Style.ContainerView.ShadowStyle.getShadow(forState: state),
            animate: true,
            duration: ChannelAvatarView.AnimationConfig.ContainerView.duration,
            timingFunctionName: ChannelAvatarView.AnimationConfig.ContainerView.timingFunctionName
        )
    }
    
    // Toggle blur layer based on disabled status of channel.
    private func animateImageViewBlur(showBlur: Bool, blurRadius: Double, duration: CFTimeInterval) {
        showBlur ? fadeInBlurLayer(blurRadius: blurRadius, duration: duration) : fadeOutBlurLayer(duration: duration)
    }
    
    // Toggle new recording indicator visibility based on state.
    private func animateNewRecordingIndicatorVisibility(toState state: ChannelState) {
        // Only show new recording indicator when previewing.
        state == .previewing ? fadeInNewRecordingIndicator() : fadeOutNewRecordingIndicator()
    }
    
    // Upsert and show new recording indicator.
    private func fadeInNewRecordingIndicator() {
        // Upsert new recording indicator subview.
        let indicator = newRecordingIndicator ?? createNewRecordingIndicator()
        
        // Show the indicator.
        indicator.animator().alphaValue = 1
    }
    
    // Hide new recording indicator if it exists.
    private func fadeOutNewRecordingIndicator() {
        // Ensure new recording indicator subview exists.
        guard let indicator = newRecordingIndicator else {
            return
        }

        // Hide the indicator.
        indicator.animator().alphaValue = 0
    }
    
    // Upsert and fade-in the gaussian blur layer.
    private func fadeInBlurLayer(blurRadius: Double, duration: CFTimeInterval, alpha: CGFloat? = 0) {
        view.animateAsGroup(
            values: [
                NSView.AnimationKey.blurRadius: blurRadius,
                NSView.AnimationKey.backgroundColor: Color.fromRGBA(0, 0, 0, alpha!).cgColor
            ],
            duration: duration,
            timingFunctionName: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunctionName,
            onLayer: blurLayer ?? createBlurLayer()
        )
    }

    // Fade-out the gaussian blur layer and remove it.
    private func fadeOutBlurLayer(duration: CFTimeInterval) {
        // Ensure blur layer exists.
        guard let blur = blurLayer else {
            return
        }
        
        // Fade out blur layer.
        view.animateAsGroup(
            values: [
                NSView.AnimationKey.blurRadius: 0,
                NSView.AnimationKey.backgroundColor: CGColor.clear
            ],
            duration: duration,
            timingFunctionName: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunctionName,
            onLayer: blur,
            completionHandler: { [weak self] in
                // Remove blur layer from image view layer after it's faded out.
                self?.blurLayer?.removeFromSuperlayer()
                self?.blurLayer = nil
            }
        )
    }
    
    private func fadeInSpinnerView() {
        // Upsert spinner view.
        spinnerView = spinnerView ?? createSpinnerView()
        
        // Hide spinner layer with opacity.
        spinnerView!.layer?.opacity = 0.0
        
        // Start spinner.
        spinnerView!.spin()

        // Fade in opacity.
        spinnerView!.animateAsGroup(
            values: [NSView.AnimationKey.opacity: 1.0],
            duration: ChannelAvatarView.AnimationConfig.SpinnerView.enterDuration,
            timingFunctionName: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunctionName
        )
    }

    // Fade out spinner view and remove it when animation finishes.
    private func fadeOutSpinnerView() {
        if spinnerView == nil {
            return
        }
        
        spinnerView!.animateAsGroup(
            values: [NSView.AnimationKey.opacity: 0.0],
            duration: ChannelAvatarView.AnimationConfig.CheckmarkView.enterDuration,
            timingFunctionName: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunctionName,
            completionHandler: { [weak self] in
                self?.spinnerView?.removeFromSuperview()
                self?.spinnerView = nil
            }
        )
    }
    
    private func addCheckmarkView() {
        // Upsert checkmark view.
        checkmarkView = checkmarkView ?? createCheckmarkView()
        
        // Draw the checkmark.
        checkmarkView!.drawStroke()
    }

    // Fade out spinner view and remove it when animation finishes.
    private func fadeOutCheckmarkView() {
        if checkmarkView == nil {
            return
        }
        
        checkmarkView!.animateAsGroup(
            values: [NSView.AnimationKey.opacity: 0.0],
            duration: ChannelAvatarView.AnimationConfig.CheckmarkView.exitDuration,
            timingFunctionName: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunctionName,
            completionHandler: { [weak self] in
                self?.checkmarkView?.removeFromSuperview()
                self?.checkmarkView = nil
            }
        )
    }
    
    private func addVideoPreviewLayer(session: AVCaptureSession) {
        // Ensure user has camera enabled.
        guard UserSettings.Video.useCamera else {
            return
        }
                
        videoPreviewLayer = videoPreviewLayer ?? createVideoPreviewLayer(session: session)
    
        DispatchQueue.main.async {
            // Add video preview layer as sublayer to image view.
            self.imageView.layer?.addSublayer(self.videoPreviewLayer!)
        }
    }
    
    private func removeVideoPreviewLayer() {
        if videoPreviewLayer == nil {
            return
        }
        
        DispatchQueue.main.async {
            self.videoPreviewLayer?.removeFromSuperlayer()
            self.videoPreviewLayer = nil
        }
    }
    
    private func fadeInLoaderView() {
        // Upsert loader view.
        loaderView = loaderView ?? createLoaderView()
        
        // Hide loader layer with opacity.
        loaderView!.layer?.opacity = 0.0
        
        // Start loader.
        loaderView!.spin()
 
        // Fade in opacity.
        loaderView!.animateAsGroup(
            values: [NSView.AnimationKey.opacity: 1.0],
            duration: ChannelAvatarView.AnimationConfig.LoaderView.enterDuration,
            timingFunctionName: ChannelAvatarView.AnimationConfig.LoaderView.timingFunctionName
        )
    }

    // Fade out loader view and remove it when animation finishes.
    private func fadeOutLoaderView() {
        if loaderView == nil {
            return
        }
        
        loaderView!.animateAsGroup(
            values: [NSView.AnimationKey.opacity: 0.0],
            duration: ChannelAvatarView.AnimationConfig.LoaderView.exitDuration,
            timingFunctionName: ChannelAvatarView.AnimationConfig.LoaderView.timingFunctionName,
            completionHandler: { [weak self] in
                self?.loaderView?.removeFromSuperview()
                self?.loaderView = nil
            }
        )
    }

    private func renderIdle(_ state: ChannelState) {
        // Animate avatar view size.
        animateAvatarViewSize(toState: state)
        
        // Animate container view drop shadow.
        animateContainerViewShadow(toState: state)
        
        // Fade out new recording indicator.
        fadeOutNewRecordingIndicator()
    }
    
    private func renderPreviewing(_ state: ChannelState) {
        // Animate avatar view size.
        animateAvatarViewSize(toState: state)
        
        // Animate container view drop shadow.
        animateContainerViewShadow(toState: state)
        
        // Fade in new recording indicator.
        fadeInNewRecordingIndicator()
    }
    
    private func renderInitializingRecording(_ state: ChannelState) {
        // Animate avatar view size.
        animateAvatarViewSize(toState: state)
        
        // Animate container view drop shadow.
        animateContainerViewShadow(toState: state)
        
        // Fade out new recording indicator.
        fadeOutNewRecordingIndicator()
        
        // Fade in the loader view if using video.
        if UserSettings.Video.useCamera {
            fadeInLoaderView()
        }
    }
    
    private func renderStartedRecording(_ state: ChannelState) {
        // Fade out loader view.
        fadeOutLoaderView()
        
        // Animate avatar view size.
        animateAvatarViewSize(toState: state)
    }
    
    private func renderCancellingRecording(_ state: ChannelState) {
        // Fade out blur layer to avatar image.
        fadeOutBlurLayer(duration: ChannelAvatarView.AnimationConfig.CheckmarkView.exitDuration)
        
        // Fade out loader view.
        fadeOutLoaderView()
    }
    
    private func renderSendingRecording(_ state: ChannelState) {
        // Fade in blur layer to avatar image.
        fadeInBlurLayer(
            blurRadius: ChannelAvatarView.Style.BlurLayer.spinBlurRadius,
            duration: ChannelAvatarView.AnimationConfig.SpinnerView.enterDuration,
            alpha: ChannelAvatarView.Style.BlurLayer.spinAlpha
        )

        // Fade in spinner view.
        fadeInSpinnerView()
    }

    private func renderSentRecording(_ state: ChannelState) {
        // Fade out spinner view.
        fadeOutSpinnerView()
        
        // Show checkmark.
        addCheckmarkView()
    }
    
    private func renderFinishedRecording(_ state: ChannelState) {
        // Fade out blur layer to avatar image.
        fadeOutBlurLayer(duration: ChannelAvatarView.AnimationConfig.CheckmarkView.exitDuration)
        
        // Fade out checkmark.
        fadeOutCheckmarkView()
    }
    
    // Render recording-specific view updates.
    private func renderRecording(_ state: ChannelState, _ recordingStatus: RecordingStatus) {
        switch recordingStatus {
        case .initializing:
            renderInitializingRecording(state)
        case .started:
            renderStartedRecording(state)
        case .cancelling:
            renderCancellingRecording(state)
        case .sending:
            renderSendingRecording(state)
        case .sent:
            renderSentRecording(state)
        case .finished:
            renderFinishedRecording(state)
        }
    }

    // Render view and subviews based on channel state.
    func render(_ state: ChannelState) {
        switch state {
        case .idle:
            renderIdle(state)
        case .previewing:
            renderPreviewing(state)
        case .recording(let recordingStatus):
            renderRecording(state, recordingStatus)
        }
    }
}
