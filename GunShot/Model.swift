import RealityKit
import SwiftUI

@Observable
class Model {
    var resourceLoaded: Bool = false

    var bulletCount = 0
    var totalBullet = 7
    var shootSpeed = 1
    var singleShootMode = false
    
    var totalScore: Float = 0
    var lastShootTime: Date? = Date()
    var gunTriggerReleased: Bool = true
    var gunRay: Ray? = nil
    var targetRotatingAngle: Int = 45
    var previousGunMatrix: FixedSizeQueue<simd_float4x4> = FixedSizeQueue(maxSize: 3)
    var targetTriangles: [Triangle] = []
    var isReloading: Bool = false
    var clearingToy: Bool = false
    
    var finishSetting: Bool = false
    var addingToy: ToyType? = nil
    var toyResource = ToyResources()
    var bulletResource = BulletResources()
    var bullets: Set<IBullet> = []
    var guns: [IGun] = []
    var soundResource = SoundResources()
    var reloadSoundEntity = Entity()
    var portals: Set<PortalBullet> = []
    var toyEntities: Set<Entity> = []
    var objects: Set<IObject> = []
    var grabbingEntity: BasketballBullet? = nil
    
    
    func reset(){
        previousGunMatrix.clear()
        bulletCount = 0
        lastShootTime = nil
        gunTriggerReleased = true
        gunRay = nil
        totalScore = 0
    }
    
    var gunType = GunType.tennisRacket
    var boxStatus: TargetStatus = .NotLoaded
    
    @MainActor
    func loadResource(scene: Entity) async{
        self.guns = [
            await ToyGun(shootSound: self.soundResource.toyShootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene),
            await PepsiGun(shootSound: self.soundResource.shootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene),
            await PinkGun(shootSound: self.soundResource.shootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene),
            await PortalGun(shootSound: self.soundResource.laserShootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene),
            await StylizedOldGun(shootSound: self.soundResource.shootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene),
            await TracersGun(shootSound: self.soundResource.laserShootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene),
            await DartGun(shootSound: self.soundResource.dartShootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene),
            await BasketballGun(shootSound: self.soundResource.dartShootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene),
            await Crossbow(shootSound: self.soundResource.bowShootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene),
            await TennisRacket(shootSound: self.soundResource.bowShootSound, reloadSound: self.soundResource.reloadSound).load(scene: scene)
        ]
        
        if let t = scene.findEntity(named: "rocket_1"){
            self.toyResource.rocket1 = t
            t.name = "rocket"
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "rocket_2"){
            self.toyResource.rocket2 = t
            t.name = "rocket"
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "rocket_3"){
            self.toyResource.rocket3 = t
            t.name = "rocket"
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "pepsi"){
            t.scale = SIMD3(repeating: 0.006)
            t.name = "pepsi"
            self.toyResource.pepsi = t
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "dart_board"){
            t.scale = SIMD3(repeating: 0.01)
            t.name = "dart_board"
            self.toyResource.dartBoard = t
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "pepsi_bullet"){
            t.scale = SIMD3(repeating: 0.006)
            self.bulletResource.pepsi = t
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "metal_ball_bullet"){
            t.scale = SIMD3(repeating: 0.2)
            self.bulletResource.metalBall = t
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "duck"){
            t.scale = SIMD3(repeating: 0.003)
            self.toyResource.duck = t
            t.name = "duck"
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "Jinxs_bullet"){
            t.scale = SIMD3(repeating: 0.0001)
            self.bulletResource.jinxsBullet = t
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "arrow"){
            t.scale = SIMD3(repeating: 0.0003)
            self.bulletResource.arrow = t
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "dart"){
            t.scale = SIMD3(repeating: 0.0002)
            self.bulletResource.dart = t
            t.name = "dart_bullet"
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "basketball"){
            t.scale = SIMD3(repeating: 0.0013)
            self.bulletResource.basketball = t
            t.removeFromParent()
        }
        
        if let t = scene.findEntity(named: "Magic_Portal"){
            t.scale = SIMD3(repeating: 0.003)
            self.bulletResource.portal = t
            t.removeFromParent()
        }
        
        if let modelEntity = try? await ModelEntity(
            named: "Basketball_Hoop_Panel.usdz",
            in: Bundle.main
        ) {
            var shapes: [ShapeResource] = []
            let angle = Float.pi*2/25
            for i in 0..<25 {
                let currentAngle = angle*Float(i)
                let shape = ShapeResource.generateBox(width: 5, height: 1, depth: 1)
                    .offsetBy(rotation: simd_quatf(angle: currentAngle, axis: [0,1,0]),translation: [sin(currentAngle)*19.5, 233, 117.5+cos(currentAngle)*19.5])
                shapes.append(shape)
            }
            
            shapes.append(ShapeResource.generateBox(width: 132, height: 87, depth: 4).offsetBy(translation: [0, 255, 86]))
            shapes.append(ShapeResource.generateBox(width: 40, height: 10, depth: 40).offsetBy(translation: [0, 5, 0]))
            shapes.append(ShapeResource.generateBox(width: 16, height: 200, depth: 16).offsetBy(translation: [0, 110, 0]))
            shapes.append(ShapeResource.generateBox(width: 18, height: 90, depth: 12).offsetBy(rotation: simd_quatf(angle: Float.pi/4+0.2, axis: [1,0,0]), translation: [0, 222, 45]))

            modelEntity.generateCollisionShapes(recursive: true)
            let modelCollisionComponent = CollisionComponent(
                shapes: shapes
            )
            modelEntity.components.set(modelCollisionComponent)
            modelEntity.components[PhysicsBodyComponent.self] = PhysicsBodyComponent(
                shapes: modelCollisionComponent.shapes,
                mass: 0,
                material: nil,
                mode: .static
            )

            modelEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
            self.toyResource.basketballPanel = modelEntity
        }
    }
}

enum GunType{
    case toy
    case pepsiGun
    case pinkGun
    case portalGun
    case stylizedOldGun
    case tracersGun
    case dartGun
    case basketballGun
    case crossbow
    case tennisRacket
}

enum TargetStatus{
    case NotLoaded
    case Ready
    case Adding
    case Added
}

enum ToyType{
    case Rocket
    case Pepsi
    case Duck
    case DartBoard
    case BasketballPanel
}

class ToyResources {
    var rocket1: Entity? = nil
    var rocket2: Entity? = nil
    var rocket3: Entity? = nil
    var pepsi: Entity? = nil
    var duck: Entity? = nil
    var dartBoard: Entity? = nil
    var basketballPanel: Entity? = nil
}

enum BulletType{
    case ball
    case jinxsBullet
    case pepsi
    case metalBall
    case portalBullet
    case dart
    case basketball
    case arrow
}

class BulletResources {
    var jinxsBullet: Entity? = nil
    var pepsi: Entity? = nil
    var metalBall: Entity? = nil
    var portal: Entity? = nil
    var dart: Entity? = nil
    var basketball: Entity? = nil
    var arrow: Entity? = nil
}

class SoundResources{
    var shootSound: AudioFileResource! = nil
    var reloadSound: AudioFileResource! = nil

    var ballHitSound: AudioFileResource! = nil
    var metalHitMetalSound: AudioFileResource! = nil
    var metalHitWallSound: AudioFileResource! = nil
    var metalHitTargetSound: AudioFileResource! = nil
    var teleportSound: AudioFileResource! = nil
    var basketballSound: AudioFileResource! = nil
    var dartSound: AudioFileResource! = nil
    var arrowHitSound: AudioFileResource! = nil
    var bowShootSound: AudioFileResource! = nil
    var dartShootSound: AudioFileResource! = nil
    var laserShootSound: AudioFileResource! = nil
    var toyShootSound: AudioFileResource! = nil
}
