import RealityKit
import SwiftUI

@MainActor
class PortalGun: IGun{
    
    init(shootSound: AudioFileResource, reloadSound: AudioFileResource){
        super.init(triggerAngle: 45, scale: 0.0032, name: "Portal_Gun", gunType: GunType.portalGun, bulletType: BulletType.portalBullet, positionOffset: .init(0.03, 0.04, -0.35), shootSound: shootSound, reloadSound: reloadSound)
    }
}
