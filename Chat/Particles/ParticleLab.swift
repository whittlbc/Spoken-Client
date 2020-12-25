//
//  ParticleLab.swift
//  Chat
//
//  Created by Ben Whittle on 12/24/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa
import Metal
import MetalPerformanceShaders
import MetalKit

class ParticleLab: MTKView
{
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
    
    private var threadsPerThreadgroup:MTLSize!
    private var threadgroupsPerGrid:MTLSize!
    
    let particleCount: Int
    let alignment:Int = 0x4000
    let particlesMemoryByteSize:Int
    
    private var particlesMemory:UnsafeMutableRawPointer? = nil
    private var particlesVoidPtr: OpaquePointer!
    private var particlesParticlePtr: UnsafeMutablePointer<Particle>!
    private var particlesParticleBufferPtr: UnsafeMutableBufferPointer<Particle>!
    
    private var gravityWellParticle = Particle(A: Vector4(x: 0, y: 0, z: 0, w: 0),
        B: Vector4(x: 0, y: 0, z: 0, w: 0),
        C: Vector4(x: 0, y: 0, z: 0, w: 0),
        D: Vector4(x: 0, y: 0, z: 0, w: 0))
    
    private var frameStartTime: CFAbsoluteTime!
    private var frameNumber = 0
    let particleSize = MemoryLayout<Particle>.size

    weak var particleLabDelegate: ParticleLabDelegate?
    
    var particleColor = ParticleColor(R: 1, G: 0.8, B: 0.4, A: 1)
    var dragFactor: Float = 0.97
    var respawnOutOfBoundsParticles = false
    
    lazy var blur: MPSImageGaussianBlur =
    {
        [unowned self] in
        return MPSImageGaussianBlur(device: self.device!, sigma: 3)
    }()
    
    lazy var erode: MPSImageAreaMin =
    {
        [unowned self] in
        return MPSImageAreaMin(device: self.device!, kernelWidth: 5, kernelHeight: 5)
    }()
    
    var clearOnStep = true
    
    let statusPrefix: String
    var statusPostix: String = ""
    
    init(width: UInt, height: UInt, numParticles: ParticleCount) {
        particleCount = numParticles.rawValue
        
        imageWidth = width
        imageHeight = height
        
        bytesPerRow = 4 * imageWidth
        
        region = MTLRegionMake2D(0, 0, Int(imageWidth), Int(imageHeight))
        blankBitmapRawData = [UInt8](unsafeUninitializedCapacity: Int(imageWidth * imageHeight * 4), initializingWith: {_, _ in})
        particlesMemoryByteSize = particleCount * MemoryLayout<Particle>.size
    
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = NumberFormatter.Style.decimal
        
        statusPrefix = formatter.string(from: NSNumber(value: numParticles.rawValue * 4))! + " Particles"
 
        super.init(frame: CGRect(x: 0, y: 0, width: Int(width), height: Int(height)), device:  MTLCreateSystemDefaultDevice())
        
        framebufferOnly = false
        drawableSize = CGSize(width: CGFloat(imageWidth), height: CGFloat(imageHeight));

        wantsLayer = true
        layer?.backgroundColor = CGColor.clear
        layer?.isOpaque = false
        layer?.masksToBounds = true
        layer?.cornerRadius = frame.size.height / 2
        
        setUpParticles()
        
        setUpMetal()
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
        
        resetParticles(edgesOnly: true)
    }
    
    func resetGravityWells() {
        setGravityWellProperties(gravityWell: .One, normalisedPositionX: 0.5, normalisedPositionY: 0.5, mass: 0, spin: 0)
        setGravityWellProperties(gravityWell: .Two, normalisedPositionX: 0.5, normalisedPositionY: 0.5, mass: 0, spin: 0)
        setGravityWellProperties(gravityWell: .Three, normalisedPositionX: 0.5, normalisedPositionY: 0.5, mass: 0, spin: 0)
        setGravityWellProperties(gravityWell: .Four, normalisedPositionX: 0.5, normalisedPositionY: 0.5, mass: 0, spin: 0)
    }
    
    func resetParticles(edgesOnly: Bool = false) {
        func rand() -> Float32 {
            return Float(drand48() - 0.5) * 0.005
        }
        
        let imageWidthDouble = Double(35)
        let imageHeightDouble = Double(35)
        let widthOffset = Float((Double(imageWidth) - imageWidthDouble) / 2)
        let heightOffset = Float((Double(imageHeight) - imageHeightDouble) / 2)
        
        for index in particlesParticleBufferPtr.startIndex ..< particlesParticleBufferPtr.endIndex {
            var positionAX = Float(drand48() * imageWidthDouble) + widthOffset
            var positionAY = Float(drand48() * imageHeightDouble) + heightOffset
            
            var positionBX = Float(drand48() * imageWidthDouble) + widthOffset
            var positionBY = Float(drand48() * imageHeightDouble) + heightOffset
            
            var positionCX = Float(drand48() * imageWidthDouble) + widthOffset
            var positionCY = Float(drand48() * imageHeightDouble) + heightOffset
            
            var positionDX = Float(drand48() * imageWidthDouble) + widthOffset
            var positionDY = Float(drand48() * imageHeightDouble) + heightOffset
//
//            if edgesOnly {
//                let positionRule = Int(arc4random() % 4)
//
//                if positionRule == 0
//                {
//                    positionAX = 0
//                    positionBX = 0
//                    positionCX = 0
//                    positionDX = 0
//                }
//                else if positionRule == 1
//                {
//                    positionAX = Float(imageWidth)
//                    positionBX = Float(imageWidth)
//                    positionCX = Float(imageWidth)
//                    positionDX = Float(imageWidth)
//                }
//                else if positionRule == 2
//                {
//                    positionAY = 0
//                    positionBY = 0
//                    positionCY = 0
//                    positionDY = 0
//                }
//                else
//                {
//                    positionAY = Float(imageHeight)
//                    positionBY = Float(imageHeight)
//                    positionCY = Float(imageHeight)
//                    positionDY = Float(imageHeight)
//                }
//            }
            
            let particle = Particle(
                A: Vector4(x: positionAX, y: positionAY, z: rand(), w: rand()),
                B: Vector4(x: positionBX, y: positionBY, z: rand(), w: rand()),
                C: Vector4(x: positionCX, y: positionCY, z: rand(), w: rand()),
                D: Vector4(x: positionDX, y: positionDY, z: rand(), w: rand())
            )
            
            particlesParticleBufferPtr[index] = particle
        }
    }
    
    private func setUpMetal() {
        device = MTLCreateSystemDefaultDevice()
        
        guard let device = device else {
            particleLabDelegate?.particleLabMetalUnavailable()
            return
        }
        
        defaultLibrary = device.makeDefaultLibrary()
        commandQueue = device.makeCommandQueue()
        kernelFunction = defaultLibrary.makeFunction(name: "particleRendererShader")
        
        do {
            try pipelineState = device.makeComputePipelineState(function: kernelFunction!)
        } catch {
            fatalError("newComputePipelineStateWithFunction failed ")
        }

        let threadExecutionWidth = pipelineState.threadExecutionWidth
        
        threadsPerThreadgroup = MTLSize(width:threadExecutionWidth,height:1,depth:1)
        threadgroupsPerGrid = MTLSize(width:particleCount / threadExecutionWidth, height:1, depth:1)
        
        frameStartTime = CFAbsoluteTimeGetCurrent()

        var imageWidthFloat = Float(imageWidth)
        var imageHeightFloat = Float(imageHeight)
        
        imageWidthFloatBuffer =  device.makeBuffer(bytes: &imageWidthFloat, length: MemoryLayout<Float>.size, options: [])
        
        imageHeightFloatBuffer = device.makeBuffer(bytes: &imageHeightFloat, length: MemoryLayout<Float>.size, options: [])
    }
    
    func stepThrough() {
        guard let device = device else {
            particleLabDelegate?.particleLabMetalUnavailable()
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
        
        let colorBuffer = device.makeBuffer(bytes: &particleColor, length: MemoryLayout<ParticleColor>.size, options: [])
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
    }
    
    override func draw(_ dirtyRect: CGRect) {
        guard let device = device else {
            particleLabDelegate?.particleLabMetalUnavailable()
            return
        }
        
        frameNumber += 1
        
        if frameNumber == 100 {
            let frametime = (CFAbsoluteTimeGetCurrent() - frameStartTime) / 100
           
            statusPostix = String(format: " at %.1f fps", 1 / frametime)
   
            frameStartTime = CFAbsoluteTimeGetCurrent()
            
            frameNumber = 0
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        
        commandEncoder!.setComputePipelineState(pipelineState)
        
        let particlesBufferNoCopy = device.makeBuffer(bytesNoCopy: particlesMemory!, length: Int(particlesMemoryByteSize),
            options: [], deallocator: nil)
        
        commandEncoder!.setBuffer(particlesBufferNoCopy, offset: 0, index: 0)
        commandEncoder!.setBuffer(particlesBufferNoCopy, offset: 0, index: 1)
        
        let inGravityWell = device.makeBuffer(bytes: &gravityWellParticle, length: particleSize, options: [])
        commandEncoder!.setBuffer(inGravityWell, offset: 0, index: 2)
        
        let colorBuffer = device.makeBuffer(bytes: &particleColor, length: MemoryLayout<ParticleColor>.size, options: [])
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
        
        drawable.present()

        particleLabDelegate?.particleLabDidUpdate(status: statusPrefix + statusPostix)
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
        switch gravityWellIndex
        {
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
    
    final func setGravityWellProperties(gravityWell: GravityWell, normalisedPositionX: Float, normalisedPositionY: Float, mass: Float, spin: Float)
    {
        let imageWidthFloat = Float(imageWidth)
        let imageHeightFloat = Float(imageHeight)
        
        switch gravityWell
        {
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

protocol ParticleLabDelegate: NSObjectProtocol
{
    func particleLabDidUpdate(status: String)
    func particleLabMetalUnavailable()
}

enum GravityWell
{
    case One
    case Two
    case Three
    case Four
}

//  Since each Particle instance defines four particles, the visible particle count
//  in the API is four times the number we need to create.
enum ParticleCount: Int {
    case FifteenThirtySix = 1_536
    case TwentyFourtyEight = 2_048
    case EigthMillion = 32_768
    case QtrMillion = 65_536
    case HalfMillion = 131_072
    case OneMillion =  262_144
    case TwoMillion =  524_288
    case FourMillion = 1_048_576
    case EightMillion = 2_097_152
    case SixteenMillion = 4_194_304
}

//  Paticles are split into three classes. The supplied particle color defines one
//  third of the rendererd particles, the other two thirds use the supplied particle
//  color components but shifted to BRG and GBR
struct ParticleColor
{
    var R: Float32 = 0
    var G: Float32 = 0
    var B: Float32 = 0
    var A: Float32 = 1
}

struct Particle // Matrix4x4
{
    var A: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var B: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var C: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var D: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
}

// Regular particles use x and y for position and z and w for velocity
// gravity wells use x and y for position and z for mass and w for spin
struct Vector4
{
    var x: Float32 = 0
    var y: Float32 = 0
    var z: Float32 = 0
    var w: Float32 = 0
}

