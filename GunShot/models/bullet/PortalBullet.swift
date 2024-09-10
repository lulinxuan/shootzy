import ARKit
import RealityKit
import SwiftUI

@Observable
class PortalBullet: IBullet {
    let waitTime = 0.3
    var gunReloadSoundController: AudioPlaybackController? = nil
    var isReady = false
    var lastUsedTime = Date()
    var teleportSoundController: AudioPlaybackController? = nil

    private let material = PhysicsMaterialResource.generate(friction: 0.5, restitution: 0.0)

    init(ray: Ray, portalBullet: Entity, teleportSound: AudioFileResource){
        super.init()
        let placementLocation = ray.origin + ray.direction*0.1
        self.entity = portalBullet.clone(recursive: true)
        
        self.teleportSoundController = self.entity.prepareAudio(teleportSound)
        if let e = (self.entity as? HasPhysics){
            e.setPosition(placementLocation, relativeTo: nil)
            e.look(at: placementLocation - ray.direction, from: placementLocation, relativeTo: nil)
            e.name = "PortalBullet"

            e.components.set(InputTargetComponent(allowedInputTypes: .indirect))

            e.components.set(
                PhysicsBodyComponent(
                    shapes: e.collision!.shapes,
                    mass: 1.0,
                    material: material,
                    mode: .dynamic)
            )
            e.addForce(ray.direction/5, relativeTo: nil)

            self.entity.spatialAudio?.reverbLevel = -6
        }
    }
    
    override func handleCollision(targetEntity: Entity, targetName: String) {
        if targetName == "Wall" && !self.isReady{
            self.entity.components.set(PhysicsBodyComponent(
                shapes: [],
                mass: 0,
                material: material,
                mode: .static)
            )
            self.isReady = true
        }else if self.isReady{
            self.teleportSoundController?.play()
        }
    }
}
