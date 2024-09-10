import ARKit
import RealityKit
import SwiftUI

@Observable
class BallBullet: IBullet {
    let color: [UIColor] = [.systemPink, .green, .blue, .red, .orange, .black]
    var hitSoundController: AudioPlaybackController? = nil

    init(ray: Ray, hitAllSound: AudioFileResource){
        super.init()
        let placementLocation = ray.origin + ray.direction*0.1

        let e = ModelEntity(
            mesh: .generateSphere(radius: 0.02),
            materials: [SimpleMaterial(color: color.randomElement()!, isMetallic: false)],
            collisionShape: .generateBox(size: SIMD3<Float>(repeating: 0.02)),
            mass: 1.0)
        e.name = "BallBullet"
        e.setPosition(placementLocation, relativeTo: nil)
        e.components.set(InputTargetComponent(allowedInputTypes: .indirect))

        let material = PhysicsMaterialResource.generate(friction: 0.5, restitution: 0.0)
        e.components.set(
            PhysicsBodyComponent(
                shapes: e.collision!.shapes,
                mass: 1.0,
                material: material,
                mode: .dynamic)
        )
        e.components.set(PhysicsMotionComponent())
        e.addForce(ray.direction*1000, relativeTo: nil)
        self.entity = e
        self.hitSoundController = self.entity.prepareAudio(hitAllSound)
        self.entity.spatialAudio?.reverbLevel = -6
    }
    
    override func handleCollision(targetEntity: Entity, targetName: String) {
        if targetName != ""{
            if let e = (self.entity as? HasPhysics){
                let v = distance(e.physicsMotion!.linearVelocity, SIMD3())
                let p = (v * 10 / (1+v)) - 10
                self.entity.spatialAudio = SpatialAudioComponent(gain: Audio.Decibel(p))
            }
            hitSoundController?.play()
        }
    }
}

