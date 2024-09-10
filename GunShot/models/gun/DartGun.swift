import RealityKit
import SwiftUI

@MainActor
class DartGun: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.0007, name: "dart_gun", gunType: GunType.dartGun, bulletType: BulletType.dart, positionOffset: .init(0, 0.02, -0.1), shootSound: shootSound, reloadSound: reloadSound)
    }
}
