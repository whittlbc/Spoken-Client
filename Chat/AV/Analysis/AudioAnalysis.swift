//
//  AudioAnalysis.swift
//  Chat
//
//  Created by Ben Whittle on 1/10/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Accelerate
import AVFoundation

public enum AudioAnalysis {
    
    static func amplitude(forBuffer buffer: AVAudioPCMBuffer) -> Float {
        guard let floatData = buffer.floatChannelData else {
            return 0
        }

        let channelCount = Int(buffer.format.channelCount)
        let length = UInt(buffer.frameLength)
        var amp: [Float] = Array(repeating: 0, count: 2)
        
        for channel in 0 ..< channelCount {
            let data = floatData[channel]
            var rms: Float = 0
            vDSP_rmsqv(data, 1, &rms, UInt(length))
            amp[channel] = rms
        }

        return amp.reduce(0, +) / 2
    }
    
    static func fft(forBuffer buffer: AVAudioPCMBuffer) -> [Float] {
        let frameCount = buffer.frameLength
        let log2n = UInt(round(log2(Double(frameCount))))
        let bufferSizePOT = Int(1 << log2n)
        let inputCount = bufferSizePOT / 2
        let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))

        var realp = [Float](repeating: 0, count: inputCount)
        var imagp = [Float](repeating: 0, count: inputCount)

        return realp.withUnsafeMutableBufferPointer { realPointer in
            imagp.withUnsafeMutableBufferPointer { imagPointer in
                var output = DSPSplitComplex(realp: realPointer.baseAddress!,
                                             imagp: imagPointer.baseAddress!)

                let windowSize = bufferSizePOT
                var transferBuffer = [Float](repeating: 0, count: windowSize)
                var window = [Float](repeating: 0, count: windowSize)

                // Hann windowing to reduce the frequency leakage
                vDSP_hann_window(&window, vDSP_Length(windowSize), Int32(vDSP_HANN_NORM))
                vDSP_vmul((buffer.floatChannelData?.pointee)!, 1, window,
                          1, &transferBuffer, 1, vDSP_Length(windowSize))

                // Transforming the [Float] buffer into a UnsafePointer<Float> object for the vDSP_ctoz method
                // And then pack the input into the complex buffer (output)
                transferBuffer.withUnsafeBufferPointer { pointer in
                    pointer.baseAddress!.withMemoryRebound(to: DSPComplex.self,
                                                           capacity: transferBuffer.count) {
                        vDSP_ctoz($0, 2, &output, 1, vDSP_Length(inputCount))
                    }
                }

                // Perform the FFT
                vDSP_fft_zrip(fftSetup!, &output, 1, log2n, FFTDirection(FFT_FORWARD))

                var magnitudes = [Float](repeating: 0.0, count: inputCount)
                vDSP_zvmags(&output, 1, &magnitudes, 1, vDSP_Length(inputCount))

                // Normalising
                var normalizedMagnitudes = [Float](repeating: 0.0, count: inputCount)
                vDSP_vsmul(&magnitudes,
                           1,
                           [1.0 / (magnitudes.max() ?? 1.0)],
                           &normalizedMagnitudes,
                           1,
                           vDSP_Length(inputCount))

                vDSP_destroy_fftsetup(fftSetup)
                return normalizedMagnitudes
            }
        }
    }
}
