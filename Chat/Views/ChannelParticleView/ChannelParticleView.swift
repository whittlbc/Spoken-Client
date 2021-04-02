//
//  ChannelParticleView.swift
//  Chat
//
//  Created by Ben Whittle on 12/27/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation

// Particle view used for voice audio animations behind channel view.
class ChannelParticleView: ParticleView {
    
    enum AudioVisualizationConfig {
        
        static let framePeriod = 3
        
        static let amplitudeScaleFactor: Float = 7
        
        static let fftScaleFactor: Float = 0.002
        
        static let spinToMassRatio: Float = 0.6
        
        static let globalRotationStep: Float = 0.04
    }
    
    enum ExplodedConfig {
        
        static let mass: Float = 80
        
        static let spin: Float = 65
    }
    
    // Colors to use for each of the 4 particle groups.
    static let colors = ParticleColorSpec(
        A: Color.fromRGBA(95, 84, 194, 1),
        B: Color.fromRGBA(95, 84, 194, 1),
        C: Color.fromRGBA(33, 99, 240, 1),
        D: Color.fromRGBA(51, 199, 224, 1)
    )
    
    // Pipe key to use when tapping mic input.
    static let micInputPipeKey = "channelParticleView"
    
    // Initial size of this view.
    static let initialSize = ChannelWindow.Style.recordingSize(withVideo: false) // audio only size
    
    // Total number of particles to render.
    static let numParticles = ParticleCount.TwentyFourtyEight
    
    // Time to wait before applying initial gravity effects.
    static let initialGravityTimeout = 0.1
            
    // Whether particles have been purposefully exploded out of view.
    private var exploded = false
    
//    private var audioSnapshot = AudioSnapshot()
    
    private var globalRotation: Float = 0
    
    // Proper initializer to use when creating this view.
    convenience init() {
        self.init(
            width: UInt(ChannelParticleView.initialSize.width),
            height: UInt(ChannelParticleView.initialSize.height),
            numParticles: ChannelParticleView.numParticles,
            colors: ChannelParticleView.colors
        )
    }
    
    // Override delegated init.
    private override init(width: UInt, height: UInt, numParticles: ParticleCount, colors: ParticleColorSpec) {
        super.init(width: width, height: height, numParticles: numParticles, colors: colors)
        
        // Apply initial gravity to start particles from a spinning state.
        applyInitialGravity()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reset() {
        exploded = false
        resetGravityWells()
        resetParticles()
        frameCount = 0
        globalRotation = 0
        untapMic()
//        audioSnapshot = AudioSnapshot()

        DispatchQueue.main.asyncAfter(deadline: .now() + ChannelParticleView.initialGravityTimeout) { [weak self] in
            self?.respawnOutOfBoundsParticles = true
            self?.applyInitialGravity()
        }
    }
    
    func explode() {
        respawnOutOfBoundsParticles = false
        exploded = true
    }
    
    func tapMic() {
//        AV.mic.addPipe(forKey: ChannelParticleView.micInputPipeKey, pipe: { [weak self] buffer in
//            self?.analyzeAudio(buffer: buffer)
//        })
    }
    
    func untapMic() {
//        AV.mic.removePipe(forKey: ChannelParticleView.micInputPipeKey)
    }
    
    private func analyzeAudio(buffer: AVAudioPCMBuffer) {
        // Calculate amplitude of mic input.
        calculateAudioAmplitude(buffer: buffer)
        
        // Calculate high/low min/max of mic input.
        calculateAudioMinMax(buffer: buffer)
    }
    
    private func calculateAudioAmplitude(buffer: AVAudioPCMBuffer) {
//        audioSnapshot.amplitude = Float(AudioAnalysis.amplitude(forBuffer: buffer) * AudioVisualizationConfig.amplitudeScaleFactor)
    }
    
    private func calculateAudioMinMax(buffer: AVAudioPCMBuffer) {
        // Perform an FFT on the buffer to get an array of normalized magnitudes.
//        let fftData = AudioAnalysis.fft(forBuffer: buffer)
//
//        // Split fft data into two halfs -- the lower half and the higher half.
//        let numFrames = fftData.count
//        let halfNumFrames = numFrames / 2
//        let lowFrames = fftData[0 ... halfNumFrames - 1]
//        let highFrames = fftData[halfNumFrames ... numFrames - 1]
//
//        // Calculate the min and max for both the lower and higher frames.
//        let lowMin = lowFrames.min() ?? 0
//        let lowMax = lowFrames.max() ?? 0
//        let highMin = highFrames.min() ?? 0
//        let highMax = highFrames.max() ?? 0
//
//        // Find indexes of each min/max.
//        audioSnapshot.lowMinIndex = Float(fftData.firstIndex(of: lowMin) ?? 0)
//        audioSnapshot.lowMaxIndex = Float(fftData.firstIndex(of: lowMax) ?? 0)
//        audioSnapshot.highMinIndex = Float((fftData.firstIndex(of: highMin) ?? 0) - halfNumFrames)
//        audioSnapshot.highMaxIndex = Float((fftData.firstIndex(of: highMax) ?? 0) - halfNumFrames)
    }
    
    private func updateGlobalRotation() {
        globalRotation += AudioVisualizationConfig.globalRotationStep
    }
    
    private func shouldApplyAudioVisualizationEffects() -> Bool {
        frameCount % AudioVisualizationConfig.framePeriod == 0
    }
    
    private func handleExplodedStep() {
        setGravityWellProperties(
            gravityWellIndex: 0,
            normalisedPositionX: 0.5,
            normalisedPositionY: 0.5,
            mass: ExplodedConfig.mass,
            spin: ExplodedConfig.spin
        )
    }
    
    private func handleAudioVisualizationStep() {
//        let radiusLow = audioSnapshot.lowMaxIndex * AudioVisualizationConfig.fftScaleFactor
//        let mass = audioSnapshot.lowMaxIndex * audioSnapshot.amplitude
//
//        setGravityWellProperties(
//            gravityWellIndex: 0,
//            normalisedPositionX: 0.5 + radiusLow * sin(globalRotation),
//            normalisedPositionY: 0.5 + radiusLow * cos(globalRotation),
//            mass: mass,
//            spin: mass * AudioVisualizationConfig.spinToMassRatio
//        )
    }
    
    func handleParticleStep() {
        // Update angle of global particle view rotation.
        updateGlobalRotation()
        
        var applyEffectsToGravityWell = false

        // If particle view has exploded, apply the explosion.
        if exploded {
            handleExplodedStep()
            applyEffectsToGravityWell = true
        }
        
        // If audio visualization effects should be applied, use the audio snapshot to do so.
        else if shouldApplyAudioVisualizationEffects() {
            handleAudioVisualizationStep()
            applyEffectsToGravityWell = true
        }
        
        // Reset all gravity wells that effects weren't applied to.
        for index in (applyEffectsToGravityWell ? 1 : 0)..<GravityWell.allCases.count {
            resetGravityWell(atIndex: index)
        }
    }
}
