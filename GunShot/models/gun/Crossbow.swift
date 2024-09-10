import RealityKit
import SwiftUI

@MainActor
class Crossbow: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.006, name: "crossbow", gunType: GunType.crossbow, bulletType: BulletType.arrow, positionOffset: .init(0.05, -0.14, 0), shootSound: shootSound, reloadSound: reloadSound)
    }

    override func load(scene: Entity) async -> IGun {
        if let gunModel = try? await ModelEntity(
            named: "crossbow.usdz",
            in: Bundle.main
        ) {
            await MainActor.run {
                gunModel.scale = SIMD3<Float>(repeating: self.scale)
                self.entity.name = self.name
                self.entity.addChild(gunModel)
                gunModel.position = positionOffset
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
        let newOri = (entity.orientation(relativeTo: nil) * simd_quatf(angle: 1.55, axis: SIMD3<Float>(x: 0, y: 1, z: 0))).normalized
        entity.setOrientation(newOri, relativeTo: nil)
        return (ray, triggerReleased, transform)
    }
}
