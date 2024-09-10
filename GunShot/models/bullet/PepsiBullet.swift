import ARKit
import RealityKit
import SwiftUI

@Observable
class PepsiBullet: IBullet {
    var hitMetalSoundController: AudioPlaybackController? = nil

    init(ray: Ray, pepsiBullet: Entity, hitMetalSound: AudioFileResource){
        super.init()
        let placementLocation = ray.origin + ray.direction*0.1

        self.entity = pepsiBullet.clone(recursive: true)
        if let e = (self.entity as? HasPhysics){
            e.setPosition(placementLocation, relativeTo: nil)
            
            e.look(at: placementLocation - ray.direction, from: placementLocation, relativeTo: nil)
            e.name = "PepsiBullet"

            e.components.set(InputTargetComponent(allowedInputTypes: .indirect))

            let material = PhysicsMaterialResource.generate(friction: 0.5, restitution: 0.0)
            e.components.set(
                PhysicsBodyComponent(
                    shapes: e.collision!.shapes,
                    mass: 1.0,
                    material: material,
                    mode: .dynamic)
            )
            self.hitMetalSoundController = self.entity.prepareAudio(hitMetalSound)
            self.entity.spatialAudio?.reverbLevel = -6
            e.addForce(ray.direction/8, relativeTo: nil)
        }
    }
    
    override func handleCollision(targetEntity: Entity, targetName: String) {
        if targetName != "" && targetName != "pepsi_gun"{
            if let e = (self.entity as? HasPhysics){
                let v = distance(e.physicsMotion!.linearVelocity, SIMD3())
                let p = (v * 30 / (1+v)) - 30
                self.entity.spatialAudio = SpatialAudioComponent(gain: Audio.Decibel(p))
            }
            hitMetalSoundController?.play()
        }
    }
}
