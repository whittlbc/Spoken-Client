//
//  MemberParticleView.swift
//  Chat
//
//  Created by Ben Whittle on 12/27/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class MemberParticleView: ParticleView {
    
    static let colors = ParticleColorSpec(
        A: Color.fromRGBA(95, 84, 194, 1),
        B: Color.fromRGBA(95, 84, 194, 1),
        C: Color.fromRGBA(33, 99, 240, 1),
        D: Color.fromRGBA(51, 199, 224, 1)
    )
    
    static let size = MemberWindow.RecordingStyle.size
    
    static let numParticles = ParticleCount.TwentyFourtyEight

    convenience init() {
        self.init(
            width: UInt(MemberParticleView.size.width),
            height: UInt(MemberParticleView.size.height),
            numParticles: MemberParticleView.numParticles,
            colors: MemberParticleView.colors
        )
    }
    
    private override init(width: UInt, height: UInt, numParticles: ParticleCount, colors: ParticleColorSpec) {
        super.init(width: width, height: height, numParticles: numParticles, colors: colors)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleParticleStep() {
        var i = 0
//
//        if spin {
//            particleView.setGravityWellProperties(
//                gravityWellIndex: 0,
//                normalisedPositionX: 0.5,
//                normalisedPositionY: 0.5,
//                mass: 70,
//                spin: 70
//            )
//
//            i = 1
//        }
//
        
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

        for index in i..<4 {
            resetGravityWell(atIndex: index)
        }
    
    }

}
