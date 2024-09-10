import RealityKit
import SwiftUI

@MainActor
class StylizedOldGun: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.0018, name: "Stylized_Old_Gun", gunType: GunType.stylizedOldGun, bulletType: BulletType.jinxsBullet, positionOffset: .init(0, 0.07, -0.07), shootSound: shootSound, reloadSound: reloadSound)
    }
}
