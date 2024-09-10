import RealityKit
import SwiftUI

@MainActor
class PepsiGun: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.013, name: "pepsi_gun", gunType: GunType.pepsiGun, bulletType: BulletType.pepsi, positionOffset: .init(0, 0, -0.08), shootSound: shootSound, reloadSound: reloadSound)
    }
}

