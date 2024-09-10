import ARKit
import RealityKit
import SwiftUI

@Observable
class JinxsBullet: IBullet {
    
    var gunReloadSoundController: AudioPlaybackController? = nil
    var hitWallSoundController: AudioPlaybackController? = nil
    var hitMetalSoundController: AudioPlaybackController? = nil
    var hitTargetSoundController: AudioPlaybackController? = nil

    init(ray: Ray, jinxsBullet: Entity, hitMetalSound: AudioFileResource, hitWallSound: AudioFileResource, hitTargetSound: AudioFileResource){
        super.init()
        let placementLocation = ray.origin + ray.direction*0.1

        self.entity = jinxsBullet.clone(recursive: true)
        if let e = (self.entity as? HasPhysics){
            e.setPosition(placementLocation, relativeTo: nil)
            e.look(at: placementLocation - ray.direction, from: placementLocation, relativeTo: nil)
            e.name = "JinxsBullet"

            e.components.set(InputTargetComponent(allowedInputTypes: .indirect))

            let material = PhysicsMaterialResource.generate(friction: 0.5, restitution: 0.0)
            e.components.set(
                PhysicsBodyComponent(
                    shapes: e.collision!.shapes,
                    mass: 1.0,
                    material: material,
                    mode: .dynamic)
            )
            self.hitWallSoundController = self.entity.prepareAudio(hitWallSound)
            self.hitMetalSoundController = self.entity.prepareAudio(hitMetalSound)
            self.hitTargetSoundController = self.entity.prepareAudio(hitTargetSound)

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
            switch targetName{
                case "pepsi": hitMetalSoundController?.play()
                case "rocket": hitMetalSoundController?.play()
                case "duck": hitTargetSoundController?.play()
                case "cube": hitTargetSoundController?.play()
                case "Wall": hitWallSoundController?.play()
                default: print(targetName)
            }
        }
    }
}
