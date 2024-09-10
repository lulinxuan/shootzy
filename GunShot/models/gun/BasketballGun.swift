import RealityKit
import SwiftUI

@MainActor
class BasketballGun: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.001, name: "basketball_gun", gunType: GunType.basketballGun, bulletType: BulletType.basketball, positionOffset: .init(0, 0.1, -0.05), shootSound: shootSound, reloadSound: reloadSound)
    }
}
