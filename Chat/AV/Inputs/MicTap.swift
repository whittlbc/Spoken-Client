//
//  Mic.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation

class MicTap {
    
    let bus: AVAudioNodeBus = 0
    
    let framesPerPacket: UInt32 = 1152
    
    let packetSize: UInt32 = 8
    
    var bufferSize: UInt32 { framesPerPacket * packetSize }
    
    var isConfigured = false
    
    var recordingData: Data? { audioRecorder.recordingData }
    
    private var isMicTapped = false
    
    private var audioEngine: AVAudioEngine!
    
    private var mixerNode: AVAudioMixerNode!
    
    private var converter: AVAudioConverter!
    
    private var compressedBuffer: AVAudioCompressedBuffer?

    private var audioRecorder = AudioRecorder()
        
    typealias Pipe = (AVAudioPCMBuffer) -> Void
    
    private var pipes = [String:Pipe]()
    
    func configure() {
        // No need to do anything if already configured.
        if isConfigured {
            return
        }
            
        // Configure audio engine.
        configureAudioEngine()
                
        // Start audio engine.
        startAudioEngine()
            
        // Set status to configured.
        isConfigured = true
    }
    
    func addPipe(forKey key: String, pipe: @escaping Pipe) {
        pipes[key] = pipe
    }
    
    func removePipe(forKey key: String) {
        pipes.removeValue(forKey: key)
    }
    
    func startRecording() {
        // Create new audio recording to receive mic input.
        audioRecorder.start()
        
        // Install mic tap.
        tapMic()
    }
    
    func stopRecording() {
        // Stop active audio recording.
        audioRecorder.stop()
                
        // Untap the mic.
        untapMic()
    }

    // Wipe active audio recording.
    func clearRecording() {
        audioRecorder.clear()
    }
        
    private func configureAudioEngine() {
        // Create audio engine and mixer node.
        audioEngine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()
        
        // Set volume to 0 to avoid audio feedback while recording.
        mixerNode.volume = 0

        // Build audio pipeline by attaching components.
        buildAudioPipeline()
        
        // Prepare audio engine.
        audioEngine.prepare()
    }
    
    private func buildAudioPipeline() {
        // Attach mixer node to audio engine.
        audioEngine.attach(mixerNode)

        // Connect input node to mixer node.
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: bus)
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)

        // Connect mixer node to main mixer node.
        let mainMixerNode = audioEngine.mainMixerNode
        let mixerFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inputFormat.sampleRate, channels: 1, interleaved: false)
        audioEngine.connect(mixerNode, to: mainMixerNode, format: mixerFormat)
    }

    // Start audio engine.
    private func startAudioEngine() {
        do {
            try audioEngine.start()
        } catch {
            fatalError("Audio engine failed to start with error: \(error)")
        }
    }
    
    private func tapMic() {
        // Ensure mic isn't already tapped.
        if isMicTapped {
            return
        }
        
        isMicTapped = true
        
        // Get node to tap and it's output format.
        let tapNode: AVAudioNode = mixerNode
        let format = tapNode.outputFormat(forBus: bus)

        // Prepare audio to be converted to FLAC.
        var outDesc = AudioStreamBasicDescription()
        outDesc.mSampleRate = format.sampleRate
        outDesc.mChannelsPerFrame = 1
        outDesc.mFormatID = kAudioFormatFLAC
        outDesc.mFramesPerPacket = framesPerPacket
        outDesc.mBitsPerChannel = 24
        outDesc.mBytesPerPacket = 0

        // Create audio converter.
        let convertFormat = AVAudioFormat(streamDescription: &outDesc)!
        converter = AVAudioConverter(from: format, to: convertFormat)

        audioEngine.inputNode.installTap(
            onBus: bus,
            bufferSize: bufferSize,
            format: format
        ) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self?.handleMicInput(buffer: buffer, when: when, convertFormat: convertFormat)
        }
    }
    
    private func untapMic() {
        // Ensure mic is currently tapped.
        guard isMicTapped else {
            return
        }
        
        isMicTapped = false

        // Untap mixer node.
        mixerNode.removeTap(onBus: bus)
        
        // Reset audio converter.
        converter.reset()
    }
    
    private func handleMicInput(buffer: AVAudioPCMBuffer, when: AVAudioTime, convertFormat: AVAudioFormat) {
        // Pipe unconverted buffer to any custom pipes.
        for pipe in pipes.values {
            pipe(buffer)
        }
        
        // Get new compressed buffer.
        compressedBuffer = newCompressedBuffer(convertFormat: convertFormat)

        var outError: NSError? = nil
        
        // Convert audio to FLAC.
        converter.convert(to: compressedBuffer!, error: &outError, withInputFrom: { (inNumPackets, outStatus) -> AVAudioBuffer? in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            return buffer // fill and return input buffer
        })

        // Get compressed audio buffer.
        let audioBuffer = compressedBuffer!.audioBufferList.pointee.mBuffers
        
        // Ensure compressed buffer has data.
        guard let mData = audioBuffer.mData else {
            return
        }

        // Convert compressed audio to Data type.
        let data = Data(bytes: mData, count: Int(audioBuffer.mDataByteSize))
        
        // Pipe compressed data to audio recorder.
        audioRecorder.handleMicInput(data: data)
    }
    
    private func newCompressedBuffer(convertFormat: AVAudioFormat) -> AVAudioCompressedBuffer {
        AVAudioCompressedBuffer(
            format: convertFormat,
            packetCapacity: packetSize,
            maximumPacketSize: converter.maximumOutputPacketSize
        )
    }
}
