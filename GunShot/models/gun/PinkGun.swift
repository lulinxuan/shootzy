import RealityKit
import SwiftUI

@MainActor
class PinkGun: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.0008, name: "pink_gun", gunType: GunType.pinkGun, bulletType: BulletType.metalBall, positionOffset: .init(0.01, -0.15, -0.15), shootSound: shootSound, reloadSound: reloadSound)
    }
}
