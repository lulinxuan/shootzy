import RealityKit
import SwiftUI

@MainActor
class TennisRacket: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.0008, name: "Tennis_Racket_Wilson_Blade", gunType: GunType.tennisRacket, bulletType: BulletType.arrow, positionOffset: .init(0.3, -0.01, 0), shootSound: shootSound, reloadSound: reloadSound)
    }
    
    override func load(scene: Entity) async -> IGun {
        if let gunModel = try? await ModelEntity(
            named: "Tennis_Racket_Wilson_Blade.usdz",
            in: Bundle.main
        ) {
            await MainActor.run {
                gunModel.scale = SIMD3<Float>(repeating: self.scale)
                self.entity.name = self.name
                self.entity.addChild(gunModel)
                gunModel.position = positionOffset
                let shape = ShapeResource.generateBox(width: 430, height: 20, depth: 320).offsetBy(translation: [230, 0, 0])

                gunModel.generateCollisionShapes(recursive: true)
                let modelCollisionComponent = CollisionComponent(
                    shapes: [shape]
                )
                gunModel.components.set(modelCollisionComponent)
                gunModel.components[PhysicsBodyComponent.self] = PhysicsBodyComponent(
                    shapes: modelCollisionComponent.shapes,
                    mass: 0,
                    material: nil,
                    mode: .static
                )
                gunModel.physicsBody!.isContinuousCollisionDetectionEnabled = true
                for _ in 0..<10{
                    let c = self.entity.prepareAudio(self.shootSound)
                    c.gain = -20
                    self.shootSoundControllers.append(c)
                }
                self.reloadSoundController = self.entity.prepareAudio(self.reloadSound)
                self.reloadSoundController?.gain = -20
            }
        }
    
        return self
    }
    
    override func updatePosition(fingers: [[SIMD3<Float>?]], previousGunMatrix: FixedSizeQueue<simd_float4x4>) -> (Ray, Bool, simd_float4x4) {
        let (ray, triggerReleased, transform) = super.updatePosition(fingers: fingers, previousGunMatrix: previousGunMatrix)
        let newOri = (entity.orientation(relativeTo: nil) * simd_quatf(angle: 1.6, axis: SIMD3<Float>(x: 0, y: 0, z: 1))).normalized
        entity.setOrientation(newOri, relativeTo: nil)
        return (ray, triggerReleased, transform)
    }
}
