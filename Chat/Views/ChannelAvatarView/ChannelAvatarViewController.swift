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
import WebRTC

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
    
    // Avatar recipient image subscription.
    private var recipientImageSubscription: AnyCancellable?
    
    // Channel video preview view.
    private var videoPreviewView: RTCMTLNSVideoView?

    // Subscription to av recorder state changes.
    private var avRecorderSubscription: AnyCancellable?

    // Loader view to show around avatar when loading arbitrary content.
    private var loaderView: DashSpinnerView?
    
    // Video recipient avatar view to show when recording a video message.
    private var videoRecipientView: RoundShadowView!

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
        
        // Load and set recipient avatar image.
        loadRecipientAvatarImage()
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
    
    // Fetch recipient avatar image from view model.
    private func loadRecipientAvatarImage() {
        viewModel.loadRecipientMemberAvatar()
    }
    
    // Subscribe to view model image changes.
    private func subscribeToViewModel() {
        // Set avatar image any time recipient avatar changes.
        recipientImageSubscription = viewModel.$recipientMemberAvatar.sink { [weak self] image in
            self?.setAvatarImage(to: image)
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
    private func setAvatarImage(to image: NSImage?, animate: Bool? = false) {
        if animate == true {
            imageView.animator().layer?.contents = image
        } else {
            imageView.layer?.contents = image
        }
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
        
        // Add blur layer as top-most sublayer to image view.
        imageView.layer?.addSublayer(blur)
        
        return blur
    }
        
    // Create spinner view to spin inside avatar during sending of content.
    private func createSpinnerView() -> ChasingTailSpinnerView {
        // Get size of image view frame.
        let imageSize = imageView.frame.size
        
        // Get spinner view diameter.
        let diameter = ChannelAvatarView.Style.SpinnerView.diameter()
        
        // Create spinner frame in center of image view frame.
        let spinnerFrame = NSRect(
            x: (imageSize.width - diameter) / 2,
            y: ((imageSize.height - diameter) / 2) - CGFloat(UserSettings.Video.useCamera ? 4.0 : 0.0),
            width: diameter,
            height: diameter
        )
        
        // Create new chasing tail spinner.
        let spinner = ChasingTailSpinnerView(
            frame: spinnerFrame,
            color: ChannelAvatarView.Style.SpinnerView.color,
            lineWidth: UserSettings.Video.useCamera ? 1.85 : 1.5,
            strokeBeginTime: UserSettings.Video.useCamera ? 0.375 : 0.4,
            strokeStartDuration: UserSettings.Video.useCamera ? 0.95 : 1.0,
            strokeEndDuration: UserSettings.Video.useCamera ? 0.575 : 0.6
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
        
        let length = ChannelAvatarView.Style.CheckmarkView.length()
        
        // Create checkmark frame.
        let checkmarkFrame = NSRect(
            x: (imageSize.width - length) / 2,
            y: ((imageSize.height - length) / 2) - CGFloat(UserSettings.Video.useCamera ? 4.0 : 0.0),
            width: length,
            height: length
        )
        
        // Create new self-drawn checkmark view.
        let checkmark = SelfDrawnCheckmarkView(
            frame: checkmarkFrame,
            color: ChannelAvatarView.Style.CheckmarkView.color,
            lineWidth: UserSettings.Video.useCamera ? 1.85 : 1.5,
            duration: UserSettings.Video.useCamera ? 0.125 : 0.15
        )
        
        // Add checkmark as subview of container view.
        containerView.addSubview(
            checkmark,
            positioned: NSWindow.OrderingMode.above,
            relativeTo: imageView
        )
        
        return checkmark
    }
    
    private func createVideoPreviewView() {
        // Create new video preview view.
        let previewView = RTCMTLNSVideoView(frame: imageView.frame)
        
        // Make it layer based.
        previewView.wantsLayer = true
        previewView.layer?.masksToBounds = true
        
        // Add video preview view as subview of image view.
        imageView.addSubview(previewView)
        
        // Add auto-layout constraints.
        constrainVideoPreviewView(previewView)
        
        // Store preview view.
        videoPreviewView = previewView
    }

    private func constrainVideoPreviewView(_ previewView: RTCMTLNSVideoView) {
        // Set up auto-layout for sizing/positioning.
        previewView.translatesAutoresizingMaskIntoConstraints = false
        
        // Fix size to image view size (equal height, width, and center).
        NSLayoutConstraint.activate([
            previewView.heightAnchor.constraint(equalTo: imageView.heightAnchor),
            previewView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            previewView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            previewView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])
        
        // Constrain the size to the image view's size.
        previewView.layer?.contentsGravity = .resizeAspectFill
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
            y: (imageSize.height - diameter) / 2 - 0.5,
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
    
    // Create new image view.
    private func createVideoRecipientView() -> RoundShadowView {
        // Create new round view with with drop shadow.
        let videoRecipient = RoundShadowView(
            shadowConfig: ChannelAvatarView.Style.VideoRecipientView.ShadowStyle.grounded
        )
                        
        // Make it layer based, and start it as hidden.
        videoRecipient.wantsLayer = true
        videoRecipient.layer?.masksToBounds = false
        videoRecipient.alphaValue = 0
        
        // Add video recipinet as subview above all.
        view.addSubview(
            videoRecipient,
            positioned: NSWindow.OrderingMode.above,
            relativeTo: newRecordingIndicator ?? containerView
        )
                
        // Add auto-layout constraints to video recipient.
        constrainVideoRecipientView(videoRecipient)
                
        // Create image view to go inside video recipient view.
        let recipientImageView = RoundView()
        
        // Make it layer based and ensure overflow is hidden.
        recipientImageView.wantsLayer = true
        recipientImageView.layer?.masksToBounds = true
        
        // Add border around avatar.
        recipientImageView.layer?.borderColor = ChannelAvatarView.Style.VideoRecipientView.BorderStyle.color
        recipientImageView.layer?.borderWidth = ChannelAvatarView.Style.VideoRecipientView.BorderStyle.width
        
        // Add image view to video recipient view.
        videoRecipient.addSubview(recipientImageView)
        
        // Set up auto-layout for sizing/positioning.
        recipientImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Fix image size to video recipient size (equal height, width, and center).
        NSLayoutConstraint.activate([
            recipientImageView.heightAnchor.constraint(equalTo: videoRecipient.heightAnchor),
            recipientImageView.widthAnchor.constraint(equalTo: videoRecipient.heightAnchor),
            recipientImageView.centerXAnchor.constraint(equalTo: videoRecipient.centerXAnchor),
            recipientImageView.centerYAnchor.constraint(equalTo: videoRecipient.centerYAnchor),
        ])
                
        // Constrain the image's size to the view's size.
        recipientImageView.layer?.contentsGravity = .resizeAspectFill

        // Add recipient avatar image as contents of view.
        recipientImageView.layer?.contents = viewModel.recipientMemberAvatar!

        // Assign new recipient to instance property.
        videoRecipientView = videoRecipient
        
        // Return newly created, unwrapped, view.
        return videoRecipientView!
    }
    
    // Set up video recipient view auto-layout.
    private func constrainVideoRecipientView(_ videoRecipient: RoundShadowView) {
        // Set up auto-layout for sizing/positioning.
        videoRecipient.translatesAutoresizingMaskIntoConstraints = false

        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set height of video recipient view relative to channel avatar view.
            videoRecipient.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: ChannelAvatarView.Style.VideoRecipientView.PositionStyle.relativeHeight
            ),
            
            // Keep indicator height and width the same.
            videoRecipient.widthAnchor.constraint(equalTo: videoRecipient.heightAnchor),
            
            // Align right sides (but shift it left the specified amount).
            videoRecipient.rightAnchor.constraint(
                equalTo: view.rightAnchor,
                constant: ChannelAvatarView.Style.VideoRecipientView.PositionStyle.edgeOffset
            ),
            
            // Align bottom sides (but shift it up the specified amount).
            videoRecipient.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: ChannelAvatarView.Style.VideoRecipientView.PositionStyle.edgeOffset
            ),
        ])
    }

    // Animate the size change of avatar view for the given channel state.
    private func animateAvatarViewSize(toState state: ChannelState) {
        let diameter = ChannelWindow.Style.size(forState: state).height
        
        avatarView.animateSize(toDiameter: diameter)

        if let blur = blurLayer {
            blur.frame = NSRect(x: 0, y: 0, width: diameter, height: diameter)
        }
    }
    
    // Toggle the amount of drop shadow for container view based on state.
    private func animateContainerViewShadow(toState state: ChannelState) {
        containerView.updateShadow(
            toConfig: ChannelAvatarView.Style.ContainerView.ShadowStyle.getShadow(forState: state),
            animate: true,
            duration: ChannelAvatarView.AnimationConfig.ContainerView.duration,
            timingFunction: ChannelAvatarView.AnimationConfig.ContainerView.timingFunction
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
            timingFunction: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunction,
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
            timingFunction: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunction,
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
            timingFunction: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunction
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
            timingFunction: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunction,
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
            timingFunction: ChannelAvatarView.AnimationConfig.BlurLayer.timingFunction,
            completionHandler: { [weak self] in
                self?.checkmarkView?.removeFromSuperview()
                self?.checkmarkView = nil
            }
        )
    }

    private func connectVideoPreviewToLocalStream() {
        if let previewView = videoPreviewView {
            AV.streamManager.renderLocalStream(to: previewView)
        }
    }
    
    private func showVideoPreviewView() {
        // Reveal video preview view.
        videoPreviewView?.alphaValue = 1.0
        
        // Fade out the blur.
        fadeOutBlurLayer(duration: ChannelAvatarView.AnimationConfig.VideoPreviewLayer.removeBlurDuration)
    }
        
    private func removeVideoPreviewView(lastFrame: NSImage? = nil, wasCancelled: Bool = false) {
        if videoPreviewView == nil {
            return
        }
        
        videoPreviewView!.alphaValue = 0.0
        
        if let image = lastFrame {
            dataProvider.user.setVideoPlaceholder(id: Session.currentUserId!, image: image)
        }
        
        DispatchQueue.main.async {
            if let image = lastFrame, !wasCancelled {
                self.setAvatarImage(to: image)
            }
            
            self.videoPreviewView!.removeFromSuperview()
            self.videoPreviewView = nil
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
            timingFunction: ChannelAvatarView.AnimationConfig.LoaderView.timingFunction
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
            timingFunction: ChannelAvatarView.AnimationConfig.LoaderView.timingFunction,
            completionHandler: { [weak self] in
                self?.loaderView?.removeFromSuperview()
                self?.loaderView = nil
            }
        )
    }

    private func upsertVideoPlaceholderAvatar() {
        viewModel.upsertVideoPlaceholderAvatar()
    }
    
    private func fadeInVideoPlaceholderAvatar() {
        if let image = viewModel.getVideoPlaceholderAvatar() {
            setAvatarImage(to: image, animate: true)
        }
    }
    
    private func fadeOutVideoPlaceholderAvatar() {
        setAvatarImage(to: viewModel.recipientMemberAvatar!, animate: true)
    }
    
    // Upsert and show video recipient view.
    private func fadeInVideoRecipientView() {
        // Upsert video recipient subview.
        let videoRecipient = videoRecipientView ?? createVideoRecipientView()
        
        // Show the video recipient.
        videoRecipient.animator().alphaValue = 1
    }
    
    // Hide video recipient view if it exists.
    private func fadeOutVideoRecipientView() {
        // Ensure video recipient subview exists.
        guard let videoRecipient = videoRecipientView else {
            return
        }

        // Hide the video recipient.
        videoRecipient.animator().alphaValue = 0
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
        
        // If recording a video message...
        if UserSettings.Video.useCamera {
            // Fade in the loader.
            fadeInLoaderView()
            
            // Upsert the video placeholder avatar.
            upsertVideoPlaceholderAvatar()
            
            // Create the video preview view.
            createVideoPreviewView()
        }
    }
    
    private func renderStartedRecording(_ state: ChannelState) {
        // If recording a video message...
        if UserSettings.Video.useCamera {
            // Fade out loader view.
            fadeOutLoaderView()

            // Set the imageView to show the video placeholder avatar.
            fadeInVideoPlaceholderAvatar()
            
            // Fade in blur layer.
            fadeInBlurLayer(
                blurRadius: ChannelAvatarView.Style.BlurLayer.videoPlaceholderAvatarBlurRadius,
                duration: ChannelWindow.AnimationConfig.duration(forState: state),
                alpha: ChannelAvatarView.Style.BlurLayer.videoPlaceholderAvatarAlpha
            )
            
            // Fade in video recipient avatar.
            fadeInVideoRecipientView()
            
            // Animate avatar view size.
            animateAvatarViewSize(toState: state)
            
            // Connect video preview to stream.
            connectVideoPreviewToLocalStream()
        }
    }
    
    private func renderCancellingRecording(_ state: ChannelState) {
        // Fade out blur layer to avatar image.
        fadeOutBlurLayer(duration: ChannelAvatarView.AnimationConfig.CheckmarkView.exitDuration)
        
        // Fade out loader view.
        fadeOutLoaderView()
        
        // If this was a video recording...
        if UserSettings.Video.useCamera {
            // Fade out the video placeholder image.
            fadeOutVideoPlaceholderAvatar()
            
            // Fade out the video recipient avatar.
            fadeOutVideoRecipientView()
            
            // Remove the video preview view.
            removeVideoPreviewView(wasCancelled: true)
        }
    }
    
    private func renderSendingRecording(_ state: ChannelState) {
        // TODO: Need to set avatar image to last frame of video
        
        // Fade in blur layer to avatar image.
        fadeInBlurLayer(
            blurRadius: ChannelAvatarView.Style.BlurLayer.spinBlurRadius,
            duration: ChannelAvatarView.AnimationConfig.SpinnerView.enterDuration,
            alpha: ChannelAvatarView.Style.BlurLayer.spinAlpha
        )
        
        removeVideoPreviewView()

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
        
        // If this was a video recording...
        if UserSettings.Video.useCamera {
            // Fade out the video placeholder image.
            fadeOutVideoPlaceholderAvatar()
            
            // Fade out the video recipient avatar.
            fadeOutVideoRecipientView()
            
            // Remove the video preview view.
            removeVideoPreviewView()
        }
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

    private func renderInitializingConsuming(_ state: ChannelState) {
        
    }
    
    private func renderStartedConsuming(_ state: ChannelState) {
        
    }
    
    private func renderCancellingConsuming(_ state: ChannelState) {
        
    }
    
    private func renderFinishedConsuming(_ state: ChannelState) {
        
    }

    // Render consuming-specific view updates.
    private func renderConsuming(_ state: ChannelState, _ message: Message, _ consumingStatus: ConsumingStatus) {
        switch consumingStatus {
        case .initializing:
            renderInitializingConsuming(state)
        case .started:
            renderStartedConsuming(state)
        case .cancelling:
            renderCancellingConsuming(state)
        case .finished:
            renderFinishedConsuming(state)
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
        case .consuming(let message, let consumingStatus):
            renderConsuming(state, message, consumingStatus)
        }
    }
}
