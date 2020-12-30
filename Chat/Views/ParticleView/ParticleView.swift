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

// View using Metal and gravity-based physics to simulate particle motion across a group of particles.
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
    
    private var gravityWellParticle = Particle()
    
    let particleSize = MemoryLayout<Particle>.size
    
    var particleColors: ParticleColor!
    
    var dragFactor: Float = 0.95
    
    var respawnOutOfBoundsParticles = false
    
    weak var particleViewDelegate: ParticleViewDelegate?

    var clearOnStep = true
    
    var frameCount: Int = 0
    
    private var initialGravityStep: Int = 0
    
    private let initialGravitySteps: Int = 30
    
    private var initialGravityTimer: Timer?

    private let shader = "particleShader"
    
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
        
        drawableSize = CGSize(width: CGFloat(imageWidth), height: CGFloat(imageHeight))

        setupLayer()
        
        setUpParticles()
        
        setUpMetal()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        free(particlesMemory)
    }
    
    // Make view layer-based, transparent, and round.
    private func setupLayer() {
        wantsLayer = true
        layer?.backgroundColor = CGColor.clear
        layer?.isOpaque = false
        layer?.masksToBounds = true
        layer?.cornerRadius = frame.size.height / 2
        
        // Add radial transparent gradient outwards from center, as a mask.
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.type = .radial
        gradient.colors = [NSColor.black.cgColor, CGColor(red: 0, green: 0, blue: 0, alpha: 0.2)]
        gradient.locations = [0.5, 1]
        gradient.startPoint = NSPoint(x: 0.5, y: 0.5)
        gradient.endPoint = NSPoint(x: 1, y: 1)
        layer?.mask = gradient
    }

    private func setUpParticles() {
        posix_memalign(&particlesMemory, alignment, particlesMemoryByteSize)
        
        particlesVoidPtr = OpaquePointer(particlesMemory)
        particlesParticlePtr = UnsafeMutablePointer<Particle>(particlesVoidPtr)
        particlesParticleBufferPtr = UnsafeMutableBufferPointer(start: particlesParticlePtr, count: particleCount)
        
        resetParticles()
    }
    
    // Reset properties of all gravity wells.
    func resetGravityWells() {
        for well in GravityWell.allCases {
            setGravityWellProperties(gravityWell: well)
        }
    }
    
    // Reset gravity well properties for gravity well at provided index.
    func resetGravityWell(atIndex index: Int) {
        setGravityWellProperties(gravityWellIndex: index)
    }
    
    // Create new particles across the entire drawing area.
    func resetParticles() {
        for i in particlesParticleBufferPtr.startIndex ..< particlesParticleBufferPtr.endIndex {
            particlesParticleBufferPtr[i] = newParticle()
        }
    }
    
    func newParticleVector() -> Vector4 {
        func rand() -> Float32 { Float(drand48() - 0.5) * 0.005 }

        return Vector4(
            x: Float(drand48() * Double(imageWidth)),
            y: Float(drand48() * Double(imageHeight)),
            z: rand(),
            w: rand()
        )
    }
    
    func newParticle() -> Particle {
        Particle(
            A: newParticleVector(),
            B: newParticleVector(),
            C: newParticleVector(),
            D: newParticleVector()
        )
    }
    
    private func setUpMetal() {
        guard let device = device else {
            particleViewDelegate?.particleViewMetalUnavailable()
            return
        }
        
        defaultLibrary = device.makeDefaultLibrary()
        commandQueue = device.makeCommandQueue()
        
        // Get kernal renderer function from metal file ParticleShader.metal
        kernelFunction = defaultLibrary.makeFunction(name: shader)
        
        do {
            try pipelineState = device.makeComputePipelineState(function: kernelFunction!)
        } catch {
            fatalError("newComputePipelineStateWithFunction failed with error: \(error)")
        }

        let threadExecutionWidth = pipelineState.threadExecutionWidth
        
        threadsPerThreadgroup = MTLSize(width: threadExecutionWidth, height: 1, depth: 1)
        threadgroupsPerGrid = MTLSize(width: particleCount / threadExecutionWidth, height: 1, depth: 1)
        
        var imageWidthFloat = Float(imageWidth)
        var imageHeightFloat = Float(imageHeight)
        
        imageWidthFloatBuffer =  device.makeBuffer(bytes: &imageWidthFloat, length: MemoryLayout<Float>.size, options: [])
        imageHeightFloatBuffer = device.makeBuffer(bytes: &imageHeightFloat, length: MemoryLayout<Float>.size, options: [])
    }
    
    func applyInitialGravity() {
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
    
    private func cancelInitialGravityTimer() {
        if initialGravityTimer == nil {
            return
        }
        
        initialGravityTimer!.invalidate()
        initialGravityTimer = nil
        initialGravityStep = 0
    }

    @objc private func applyInitialGravityStep() {
        var j = 0
        
        if initialGravityStep % 30 == 0 {
            setGravityWellProperties(
                gravityWellIndex: 0,
                normalisedPositionX: 0.5,
                normalisedPositionY: 0.5,
                mass: 40,
                spin: 25
            )
            
            j = 1
        }
        
        for index in j..<GravityWell.allCases.count {
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
    
    // Override draw function on each frame.
    override func draw(_ dirtyRect: CGRect) {
        stepThrough(present: true)
        frameCount += 1
    }
    
    // Get the GravityWell at the specified index.
    private func getGravityWell(atIndex index: Int) -> GravityWell {
        switch index {
        case 1:
            return .Two
        case 2:
            return .Three
        case 3:
            return .Four
        default:
            return .One
        }
    }
    
    // Get the associated gravity well particle vector component for the type of gravity well provided.
    private func getGravityParticleVectorForWell(gravityWell: GravityWell) -> Vector4 {
        switch gravityWell {
        case .One:
            return gravityWellParticle.A
        case .Two:
            return gravityWellParticle.B
        case .Three:
            return gravityWellParticle.C
        case .Four:
            return gravityWellParticle.D
        }
    }
    
    // Get the normalized x/y position of the gravity well particle for the given gravity well.
    final func getGravityWellNormalisedPosition(gravityWell: GravityWell) -> (x: Float, y: Float) {
        // Get gravity particle vector component for the given gravity well.
        let gravityParticleVector = getGravityParticleVectorForWell(gravityWell: gravityWell)
        
        return (
            x: gravityParticleVector.x / Float(imageWidth),
            y: gravityParticleVector.y / Float(imageHeight)
        )
    }
    
    // Set gravity well properties for provided index of gravity well.
    final func setGravityWellProperties(
        gravityWellIndex: Int,
        normalisedPositionX: Float = 0.5,
        normalisedPositionY: Float = 0.5,
        mass: Float = 0,
        spin: Float = 0) {
        
        setGravityWellProperties(
            gravityWell: getGravityWell(atIndex: gravityWellIndex),
            normalisedPositionX: normalisedPositionX,
            normalisedPositionY: normalisedPositionY,
            mass: mass,
            spin: spin
        )
    }
    
    // Set gravity well properties for provided gravity well.
    final func setGravityWellProperties(
        gravityWell: GravityWell,
        normalisedPositionX: Float = 0.5,
        normalisedPositionY: Float = 0.5,
        mass: Float = 0,
        spin: Float = 0) {
        
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

// Valid gravity wells inside the particle area.
enum GravityWell: CaseIterable {
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
    var A: Vector4 = Vector4()
    var B: Vector4 = Vector4()
    var C: Vector4 = Vector4()
    var D: Vector4 = Vector4()
}

// Spec making it easier to create ParticleColor structs using NSColor representations.
struct ParticleColorSpec {
    var A: NSColor
    var B: NSColor
    var C: NSColor
    var D: NSColor
    
    func createParticleColor() -> ParticleColor {
        func colorToVector(_ color: NSColor) -> Vector4 {
            Vector4(
                x: Float32(color.redComponent),
                y: Float32(color.greenComponent),
                z: Float32(color.blueComponent),
                w: Float32(color.alphaComponent)
            )
        }
        
        return ParticleColor(
            A: colorToVector(self.A),
            B: colorToVector(self.B),
            C: colorToVector(self.C),
            D: colorToVector(self.D)
        )
    }
}

// Matrix4x4 - Particle positions and velocity.
struct Particle {
    var A: Vector4 = Vector4()
    var B: Vector4 = Vector4()
    var C: Vector4 = Vector4()
    var D: Vector4 = Vector4()
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
