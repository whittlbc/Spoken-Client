//
//  MemberParticleView.swift
//  Chat
//
//  Created by Ben Whittle on 12/27/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Particle view used for voice audio animations behind member view.
class MemberParticleView: ParticleView {
    
    // Colors to use for each of the 4 particle groups.
    static let colors = ParticleColorSpec(
        A: Color.fromRGBA(95, 84, 194, 1),
        B: Color.fromRGBA(95, 84, 194, 1),
        C: Color.fromRGBA(33, 99, 240, 1),
        D: Color.fromRGBA(51, 199, 224, 1)
    )
    
    // Initial size of this view.
    static let initialSize = MemberWindow.defaultSizeForState(.recording(.started))
    
    // Total number of particles to render.
    static let numParticles = ParticleCount.TwentyFourtyEight

    private var exploding = false
    
    // Proper initializer to use when creating this view.
    convenience init() {
        self.init(
            width: UInt(MemberParticleView.initialSize.width),
            height: UInt(MemberParticleView.initialSize.height),
            numParticles: MemberParticleView.numParticles,
            colors: MemberParticleView.colors
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
        exploding = false
        resetGravityWells()
        resetParticles()
        frameCount = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.applyInitialGravity()
        }
    }
    
    func explode() {
        exploding = true
    }
    
    func handleParticleStep() {
        var i = 0

        if exploding {
            setGravityWellProperties(
                gravityWellIndex: 0,
                normalisedPositionX: 0.5,
                normalisedPositionY: 0.5,
                mass: 80,
                spin: 65
            )

            i = 1
        }
        
        if frameCount % 80 == 0 {
            setGravityWellProperties(
                gravityWellIndex: 0,
                normalisedPositionX: 0.5,
                normalisedPositionY: 0.5,
                mass: 40,
                spin: 25
            )

            i = 1
        }

        for index in i..<GravityWell.allCases.count {
            resetGravityWell(atIndex: index)
        }
    }
}
