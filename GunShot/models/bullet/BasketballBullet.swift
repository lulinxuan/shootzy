import ARKit
import RealityKit
import SwiftUI

@Observable
class BasketballBullet: IBullet {
    var basketballSoundController: AudioPlaybackController? = nil
    var attachedTime = Date()

    init(ray: Ray, basketballBullet: Entity, basketballSound: AudioFileResource){
        super.init()
        let placementLocation = ray.origin + ray.direction*0.2

        self.entity = basketballBullet.clone(recursive: true)
        if let e = (self.entity as? HasPhysics){
            e.setPosition(placementLocation, relativeTo: nil)
            e.name = "BasketballBullet"

            e.components.set(InputTargetComponent(allowedInputTypes: .indirect))

            let material = PhysicsMaterialResource.generate(friction: 0.5, restitution: 0.0)
            e.components.set(
                PhysicsBodyComponent(
                    shapes: e.collision!.shapes,
                    mass: 3.0,
                    material: material,
                    mode: .dynamic)
            )
            self.basketballSoundController = self.entity.prepareAudio(basketballSound)
            self.entity.spatialAudio?.reverbLevel = -6
            e.addForce(ray.direction/8, relativeTo: nil)
        }
    }
    
    override func handleCollision(targetEntity: Entity, targetName: String) {
        if targetName != ""{
            if let e = (self.entity as? HasPhysics){
                let v = distance(e.physicsMotion!.linearVelocity, SIMD3())
                let p = (v * 30 / (1+v)) - 30
                self.entity.spatialAudio = SpatialAudioComponent(gain: Audio.Decibel(p))
            }
            basketballSoundController?.play()
        }
    }
}
