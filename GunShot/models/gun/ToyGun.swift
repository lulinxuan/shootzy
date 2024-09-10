import RealityKit
import SwiftUI

@MainActor
class ToyGun: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.0035, name: "toy_gun", gunType: GunType.toy, bulletType: BulletType.ball, positionOffset: .init(0, 0.02, -0.05), shootSound: shootSound, reloadSound: reloadSound)
    }
}
