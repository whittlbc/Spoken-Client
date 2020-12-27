//
//  ParticleView.swift
//  Chat
//
//  Created by Ben Whittle on 12/24/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa
import Metal
import MetalPerformanceShaders
import MetalKit

class ParticleView: MTKView {
    
    let imageWidth: UInt
    let imageHeight: UInt
    
    private var imageWidthFloatBuffer: MTLBuffer!
    private var imageHeightFloatBuffer: MTLBuffer!
    
    let bytesPerRow: UInt
    let region: MTLRegion
    let blankBitmapRawData : [UInt8]
    
    private var kernelFunction: MTLFunction!
    private var pipelineState: MTLComputePipelineState!
    private var defaultLibrary: MTLLibrary! = nil
    private var commandQueue: MTLCommandQueue! = nil
    
    private var threadsPerThreadgroup: MTLSize!
    private var threadgroupsPerGrid: MTLSize!
    
    let particleCount: Int
    let alignment:Int = 0x4000
    let particlesMemoryByteSize:Int
    
    private var particlesMemory: UnsafeMutableRawPointer? = nil
    private var particlesVoidPtr: OpaquePointer!
    private var particlesParticlePtr: UnsafeMutablePointer<Particle>!
    private var particlesParticleBufferPtr: UnsafeMutableBufferPointer<Particle>!
    
    private var gravityWellParticle = Particle(
        A: Vector4(x: 0, y: 0, z: 0, w: 0),
        B: Vector4(x: 0, y: 0, z: 0, w: 0),
        C: Vector4(x: 0, y: 0, z: 0, w: 0),
        D: Vector4(x: 0, y: 0, z: 0, w: 0)
    )
    
    let particleSize = MemoryLayout<Particle>.size
    
    var particleColors: ParticleColor!
    
    var dragFactor: Float = 0.95
    
    var respawnOutOfBoundsParticles = false
    
    weak var particleViewDelegate: ParticleViewDelegate?

    var clearOnStep = true
    
    // Current frame count.
    var frameCount: Int = 0
    
    private var initialGravityStep: Int = 0
    
    private let initialGravitySteps: Int = 30
    
    private var initialGravityTimer: Timer?
    
    init(width: UInt, height: UInt, numParticles: ParticleCount, colors: ParticleColorSpec) {
        imageWidth = width
        imageHeight = height
        particleCount = numParticles.rawValue
        particleColors = colors.createParticleColor()
                        
        bytesPerRow = 4 * imageWidth
        
        let intWidth = Int(imageWidth)
        let intHeight = Int(imageHeight)
        
        region = MTLRegionMake2D(0, 0, intWidth, intHeight)
        blankBitmapRawData = [UInt8](unsafeUninitializedCapacity: Int(imageWidth * imageHeight * 4), initializingWith: {_, _ in})
        particlesMemoryByteSize = particleCount * MemoryLayout<Particle>.size
     
        super.init(frame: CGRect(x: 0, y: 0, width: intWidth, height: intHeight), device: MTLCreateSystemDefaultDevice())
        
        framebufferOnly = false
        drawableSize = CGSize(width: CGFloat(imageWidth), height: CGFloat(imageHeight));

        wantsLayer = true
        layer?.backgroundColor = CGColor.clear
        layer?.isOpaque = false
        layer?.masksToBounds = true
        layer?.cornerRadius = frame.size.height / 2
        
        setUpParticles()
        
        setUpMetal()
        
        resetParticles()
        
        applyInitialGravity()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        free(particlesMemory)
    }

    private func setUpParticles() {
        posix_memalign(&particlesMemory, alignment, particlesMemoryByteSize)
        
        particlesVoidPtr = OpaquePointer(particlesMemory)
        particlesParticlePtr = UnsafeMutablePointer<Particle>(particlesVoidPtr)
        particlesParticleBufferPtr = UnsafeMutableBufferPointer(start: particlesParticlePtr, count: particleCount)
        
        resetParticles()
    }
    
    func resetGravityWells() {
        setGravityWellProperties(gravityWell: .One, normalisedPositionX: 0.5, normalisedPositionY: 0.5, mass: 0, spin: 0)
        setGravityWellProperties(gravityWell: .Two, normalisedPositionX: 0.5, normalisedPositionY: 0.5, mass: 0, spin: 0)
        setGravityWellProperties(gravityWell: .Three, normalisedPositionX: 0.5, normalisedPositionY: 0.5, mass: 0, spin: 0)
        setGravityWellProperties(gravityWell: .Four, normalisedPositionX: 0.5, normalisedPositionY: 0.5, mass: 0, spin: 0)
    }
    
    func resetGravityWell(atIndex index: Int) {
        setGravityWellProperties(gravityWellIndex: index, normalisedPositionX: 0.5, normalisedPositionY: 0.5, mass: 0, spin: 0)
    }
    
    func resetParticles() {
        func rand() -> Float32 {
            return Float(drand48() - 0.5) * 0.005
        }
        
        let imageWidthDouble = Double(imageWidth)
        let imageHeightDouble = Double(imageHeight)
        var ax, ay, bx, by, cx, cy, dx, dy: Float

        for i in particlesParticleBufferPtr.startIndex ..< particlesParticleBufferPtr.endIndex {
            ax = Float(drand48() * imageWidthDouble)
            ay = Float(drand48() * imageHeightDouble)
            
            bx = Float(drand48() * imageWidthDouble)
            by = Float(drand48() * imageHeightDouble)
            
            cx = Float(drand48() * imageWidthDouble)
            cy = Float(drand48() * imageHeightDouble)
            
            dx = Float(drand48() * imageWidthDouble)
            dy = Float(drand48() * imageHeightDouble)
                        
            particlesParticleBufferPtr[i] = Particle(
                A: Vector4(x: ax, y: ay, z: rand(), w: rand()),
                B: Vector4(x: bx, y: by, z: rand(), w: rand()),
                C: Vector4(x: cx, y: cy, z: rand(), w: rand()),
                D: Vector4(x: dx, y: dy, z: rand(), w: rand())
            )
        }
    }
    
    private func setUpMetal() {
        device = MTLCreateSystemDefaultDevice()
        
        guard let device = device else {
            particleViewDelegate?.particleViewMetalUnavailable()
            return
        }
        
        defaultLibrary = device.makeDefaultLibrary()
        commandQueue = device.makeCommandQueue()
        kernelFunction = defaultLibrary.makeFunction(name: "particleShader")
        
        do {
            try pipelineState = device.makeComputePipelineState(function: kernelFunction!)
        } catch {
            fatalError("newComputePipelineStateWithFunction failed with error: \(error)")
        }

        let threadExecutionWidth = pipelineState.threadExecutionWidth
        
        threadsPerThreadgroup = MTLSize(width:threadExecutionWidth,height:1,depth:1)
        threadgroupsPerGrid = MTLSize(width:particleCount / threadExecutionWidth, height:1, depth:1)
        
        var imageWidthFloat = Float(imageWidth)
        var imageHeightFloat = Float(imageHeight)
        
        imageWidthFloatBuffer =  device.makeBuffer(bytes: &imageWidthFloat, length: MemoryLayout<Float>.size, options: [])
        imageHeightFloatBuffer = device.makeBuffer(bytes: &imageHeightFloat, length: MemoryLayout<Float>.size, options: [])
    }
    
    
    private func applyInitialGravity() {
        if initialGravityTimer != nil {
            return
        }
        
        initialGravityTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(1/60),
            target: self,
            selector: #selector(applyInitialGravityStep),
            userInfo: nil,
            repeats: true
        )
    }
    
    func cancelInitialGravityTimer() {
        if initialGravityTimer == nil {
            return
        }
        
        initialGravityTimer!.invalidate()
        initialGravityTimer = nil
    }

    @objc func applyInitialGravityStep() {
        var j = 0
        
        if initialGravityStep % 30 == 0 {
            setGravityWellProperties(
                gravityWellIndex: 0,
                normalisedPositionX: 0.5,
                normalisedPositionY: initialGravityStep % 15 == 0 ? 0.4 : 0.6,
                mass: 40,
                spin: 25
            )
            
            j = 1
        }
        
        for index in j..<4 {
            resetGravityWell(atIndex: index)
        }
        
        stepThrough()

        initialGravityStep += 1
        
        if initialGravityStep == initialGravitySteps {
            cancelInitialGravityTimer()
        }
    }
    
    func stepThrough(present: Bool = false) {
        guard let device = device else {
            particleViewDelegate?.particleViewMetalUnavailable()
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        
        commandEncoder!.setComputePipelineState(pipelineState)
        
        let particlesBufferNoCopy = device.makeBuffer(
            bytesNoCopy: particlesMemory!,
            length: Int(particlesMemoryByteSize),
            options: [],
            deallocator: nil
        )
        
        commandEncoder!.setBuffer(particlesBufferNoCopy, offset: 0, index: 0)
        commandEncoder!.setBuffer(particlesBufferNoCopy, offset: 0, index: 1)
        
        let inGravityWell = device.makeBuffer(bytes: &gravityWellParticle, length: particleSize, options: [])
        commandEncoder!.setBuffer(inGravityWell, offset: 0, index: 2)
        
        let colorBuffer = device.makeBuffer(bytes: &particleColors, length: MemoryLayout<ParticleColor>.size, options: [])
        commandEncoder!.setBuffer(colorBuffer, offset: 0, index: 3)
        
        commandEncoder!.setBuffer(imageWidthFloatBuffer, offset: 0, index: 4)
        commandEncoder!.setBuffer(imageHeightFloatBuffer, offset: 0, index: 5)
        
        let dragFactorBuffer = device.makeBuffer(bytes: &dragFactor, length: MemoryLayout<Float>.size, options: [])
        commandEncoder!.setBuffer(dragFactorBuffer, offset: 0, index: 6)
        
        let respawnOutOfBoundsParticlesBuffer = device.makeBuffer(bytes: &respawnOutOfBoundsParticles, length: MemoryLayout<Bool>.size, options: [])
        commandEncoder!.setBuffer(respawnOutOfBoundsParticlesBuffer, offset: 0, index: 7)

        guard let drawable = currentDrawable else {
            commandEncoder!.endEncoding()
            print("metalLayer.nextDrawable() returned nil")
            return
        }

        if clearOnStep {
            drawable.texture.replace(
                region: self.region,
                mipmapLevel: 0,
                withBytes: blankBitmapRawData,
                bytesPerRow: Int(bytesPerRow)
            )
        }
                
        commandEncoder!.setTexture(drawable.texture, index: 0)
        
        commandEncoder?.dispatchThreadgroups(threadgroupsPerGrid!, threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder!.endEncoding()
        
        commandBuffer!.commit()
        
        if !present {
            return
        }
        
        drawable.present()

        particleViewDelegate?.particleViewDidUpdate()
    }
    
    override func draw(_ dirtyRect: CGRect) {
        stepThrough(present: true)
        frameCount += 1
    }
    
    final func getGravityWellNormalisedPosition(gravityWell: GravityWell) -> (x: Float, y: Float) {
        let returnPoint: (x: Float, y: Float)
        
        let imageWidthFloat = Float(imageWidth)
        let imageHeightFloat = Float(imageHeight)

        switch gravityWell
        {
        case .One:
            returnPoint = (x: gravityWellParticle.A.x / imageWidthFloat, y: gravityWellParticle.A.y / imageHeightFloat)
            
        case .Two:
            returnPoint = (x: gravityWellParticle.B.x / imageWidthFloat, y: gravityWellParticle.B.y / imageHeightFloat)
            
        case .Three:
            returnPoint = (x: gravityWellParticle.C.x / imageWidthFloat, y: gravityWellParticle.C.y / imageHeightFloat)
            
        case .Four:
            returnPoint = (x: gravityWellParticle.D.x / imageWidthFloat, y: gravityWellParticle.D.y / imageHeightFloat)
        }

        return returnPoint
    }
    
    final func setGravityWellProperties(gravityWellIndex: Int, normalisedPositionX: Float, normalisedPositionY: Float, mass: Float, spin: Float) {
        switch gravityWellIndex {
        case 1:
            setGravityWellProperties(gravityWell: .Two, normalisedPositionX: normalisedPositionX, normalisedPositionY: normalisedPositionY, mass: mass, spin: spin)
            
        case 2:
            setGravityWellProperties(gravityWell: .Three, normalisedPositionX: normalisedPositionX, normalisedPositionY: normalisedPositionY, mass: mass, spin: spin)

        case 3:
            setGravityWellProperties(gravityWell: .Four, normalisedPositionX: normalisedPositionX, normalisedPositionY: normalisedPositionY, mass: mass, spin: spin)
            
        default:
            setGravityWellProperties(gravityWell: .One, normalisedPositionX: normalisedPositionX, normalisedPositionY: normalisedPositionY, mass: mass, spin: spin)
        }
    }
    
    final func setGravityWellProperties(gravityWell: GravityWell, normalisedPositionX: Float, normalisedPositionY: Float, mass: Float, spin: Float) {
        let imageWidthFloat = Float(imageWidth)
        let imageHeightFloat = Float(imageHeight)
        
        switch gravityWell {
        case .One:
            gravityWellParticle.A.x = imageWidthFloat * normalisedPositionX
            gravityWellParticle.A.y = imageHeightFloat * normalisedPositionY
            gravityWellParticle.A.z = mass
            gravityWellParticle.A.w = spin
            
        case .Two:
            gravityWellParticle.B.x = imageWidthFloat * normalisedPositionX
            gravityWellParticle.B.y = imageHeightFloat * normalisedPositionY
            gravityWellParticle.B.z = mass
            gravityWellParticle.B.w = spin
            
        case .Three:
            gravityWellParticle.C.x = imageWidthFloat * normalisedPositionX
            gravityWellParticle.C.y = imageHeightFloat * normalisedPositionY
            gravityWellParticle.C.z = mass
            gravityWellParticle.C.w = spin
            
        case .Four:
            gravityWellParticle.D.x = imageWidthFloat * normalisedPositionX
            gravityWellParticle.D.y = imageHeightFloat * normalisedPositionY
            gravityWellParticle.D.z = mass
            gravityWellParticle.D.w = spin
        }
    }
}

enum GravityWell {
    case One
    case Two
    case Three
    case Four
}

//  Since each Particle instance defines four particles, the visible particle count
//  in the API is four times the number we need to create.
enum ParticleCount: Int {
    case TwentyFourtyEight = 2_048
}

// Matrix4x4 - Particle colors
struct ParticleColor {
    var A: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var B: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var C: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var D: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
}

struct ParticleColorSpec {
    var A: NSColor
    var B: NSColor
    var C: NSColor
    var D: NSColor
    
    func createParticleColor() -> ParticleColor {
        ParticleColor(
            A: Vector4(
                x: Float32(self.A.redComponent),
                y: Float32(self.A.greenComponent),
                z: Float32(self.A.blueComponent),
                w: Float32(self.A.alphaComponent)
            ),
            B: Vector4(
                x: Float32(self.B.redComponent),
                y: Float32(self.B.greenComponent),
                z: Float32(self.B.blueComponent),
                w: Float32(self.B.alphaComponent)
            ),
            C: Vector4(
                x: Float32(self.C.redComponent),
                y: Float32(self.C.greenComponent),
                z: Float32(self.C.blueComponent),
                w: Float32(self.C.alphaComponent)
            ),
            D: Vector4(
                x: Float32(self.D.redComponent),
                y: Float32(self.D.greenComponent),
                z: Float32(self.D.blueComponent),
                w: Float32(self.D.alphaComponent)
            )
        )
    }
}

// Matrix4x4 - Particle positions and velocity.
struct Particle {
    var A: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var B: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var C: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var D: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
}

// Regular particles use x and y for position and z and w for velocity.
// Gravity wells use x and y for position and z for mass and w for spin.
// ParticleColor uses x,y,z,w as rgba.
struct Vector4 {
    var x: Float32 = 0
    var y: Float32 = 0
    var z: Float32 = 0
    var w: Float32 = 0
}
