import RealityKit
import SwiftUI

@MainActor
class TracersGun: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.0006, name: "Tracers_Gun_Overwatch", gunType: GunType.tracersGun, bulletType: BulletType.jinxsBullet, positionOffset: .init(0, 0.06, -0.23), shootSound: shootSound, reloadSound: reloadSound)
    }
}
