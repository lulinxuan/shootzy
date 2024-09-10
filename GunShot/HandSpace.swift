import Accelerate
import AVKit
import Combine
import GameController
import RealityKit
import SwiftUI
import RealityKitContent

struct HandSpace: View{
    @ObservedObject var trackingModel: TrackingModel
    @Environment(Model.self) var model
    @Environment(MetalViewModel.self) var metalViewModel

    let spaceOrigin = Entity()
    let cameraAnchor = AnchorEntity(.head)

    @State var target = Cube()
    @State var holes: [ModelEntity] = []
    @State var settingView: ViewAttachmentEntity! = nil
    @State var settingButton: ViewAttachmentEntity! = nil
    @State var bulletCountView: ViewAttachmentEntity! = nil
    
    @State var fingerEntities: [ModelEntity] = []
    @State var subscriptions: [EventSubscription] = []

    enum AttachmentIDs: Int {
        case holdGun = 101
        case gunBulletCount = 102
        case setting = 104
        case score = 105
        case settingButton = 106
    }
    
    var body: some View {
        RealityView { content, attachments in
            // The root entity.
            spaceOrigin.name = "origin"
            content.add(spaceOrigin)
            content.add(cameraAnchor)
            
            await loadResource(content: content)
            
            var material = UnlitMaterial()
            material.color = .init(tint: .clear ,texture: nil)
            let floor = ModelEntity(mesh: .generatePlane(width: 10, depth: 10),
                                    materials: [material],
                                    collisionShape: .generateBox(width: 10, height: 0.0001, depth: 10),
                                    mass: 0)
            floor.position.y = 0
            content.add(floor)
            
            if let attachment = attachments.entity(for: AttachmentIDs.gunBulletCount) {
                attachment.position = [0, 0.2, 0]
                self.bulletCountView = attachment
            }

            if let attachment = attachments.entity(for: AttachmentIDs.setting) {
                self.settingView = attachment
                attachment.position = [0, 1, -2]
                self.spaceOrigin.addChild(attachment)
            }
            
            if let attachment = attachments.entity(for: AttachmentIDs.score) {
                attachment.position = [0, 0.7, 0]
                self.target.entity.addChild(attachment)
            }
            
            if let attachment = attachments.entity(for: AttachmentIDs.settingButton) {
                self.settingButton = attachment
                attachment.position = [0.2, 0.2, -1]
                cameraAnchor.addChild(attachment)
            }
            for i in 0..<24{
                self.fingerEntities.append(createFingertip())
                self.fingerEntities[i].name = "left_hand_\(i)"
                content.add(self.fingerEntities[i])
            }
        } update: { updateContent,_  in
            handleUpdate(updateContent: updateContent)
            tryAddingBoxTarget()
            let toysToBeRemoved = self.model.toyEntities.filter({ distance($0.position, [0,0,0]) > 10 })
            for i in toysToBeRemoved{
                i.removeFromParent()
                self.model.toyEntities.remove(i)
            }
            
            for i in self.model.toyEntities {
                if let e = (i as? HasPhysics), i.name.contains("rocket"){
                    if distance(e.physicsMotion!.linearVelocity, SIMD3()) < 4{
                        e.addForce(i.transform.rotation.imag*30, relativeTo: nil)
                    }
                }
            }
            
            let now = Date()
            let bulletsNeedToBeRemoved = self.model.bullets.filter{bullet in
                if bullet.entity.name == "PortalBullet" {
                    if now.timeIntervalSince(bullet.creationTime) > 60{
                        self.model.portals.remove(bullet as! PortalBullet)
                        return true
                    }
                    return false
                }
                return now.timeIntervalSince(bullet.creationTime) > 10
            }
            for i in bulletsNeedToBeRemoved{
                i.entity.removeFromParent()
                self.model.bullets.remove(i)
            }
        } attachments: {
            Attachment(id: AttachmentIDs.settingButton) {
                MetalSettingbuttonView()
                    .environment(metalViewModel)
                    .frame(width: MetalSettingbuttonView.targetSize.width, height: MetalSettingbuttonView.targetSize.height)
                    .task {
                        metalViewModel.updateResolution(width: Float(MetalSettingbuttonView.targetSize.width), height: Float(MetalSettingbuttonView.targetSize.height))
                    }
                    .onTapGesture(perform: {
                        self.settingView.scale = [0.0, 0.0, 0.0]
                        model.finishSetting = false
                        openSettingView()
                    })
                    .opacity(!model.finishSetting ? 0 : 1)
                    .hoverEffect()
            }
            
            Attachment(id: AttachmentIDs.setting) {
                SettingView()
                    .environment(model)
                    .opacity(model.finishSetting ? 0 : 1)
            }
            
            Attachment(id: AttachmentIDs.gunBulletCount) {
                Text("\(self.model.totalBullet - self.model.bulletCount)/\(self.model.totalBullet)").font(.system(size: 36)).foregroundStyle(.orange)
            }
            
            Attachment(id: AttachmentIDs.score) {
                Text("Average Score: \(Float(model.totalScore) / Float(model.bulletCount == 0 ? 1 : model.bulletCount), specifier: "%.2f")").font(.system(size: 60))
                    .opacity(model.totalScore == 0.0 ? 0 : 1)
            }
        }
        .onChange(of: self.model.finishSetting, { _, newValue in
            if newValue{
                //setting closed
                self.reset(content: self.spaceOrigin)
            }
        })
        .onChange(of: self.model.addingToy, { oldValue, newValue in
            if oldValue == nil && newValue != nil{
                self.addToy()
            }
        })
        .onChange(of: self.model.gunType, { oldValue, newValue in
            self.updateGun()
        })
        .onChange(of: self.model.clearingToy, { oldValue, newValue in
            if newValue{
                self.model.clearingToy = false
                for i in self.model.toyEntities {
                    i.removeFromParent()
                }
                for i in self.model.portals {
                    i.entity.removeFromParent()
                }
                for i in self.model.objects {
                    i.entity.removeFromParent()
                }
                self.model.toyEntities.removeAll()
                self.model.portals.removeAll()
                self.model.objects.removeAll()

                self.target.entity.isEnabled = false
                self.model.boxStatus = .Ready
            }
        })
        .task {
            await trackingModel.start()
        }
        .task {
            await trackingModel.publishHandTrackingUpdates()
        }
        .task {
            await trackingModel.monitorSessionEvents()
        }
        .task(priority: .low) {
            await trackingModel.processReconstructionUpdates(contentEntity: spaceOrigin)
        }
        .gesture(
            DragGesture()
                .targetedToEntity(self.target.entity)
                .onChanged { value in
                    if !self.model.finishSetting{
                        self.target.entity.position = value.convert(value.location3D, from: .local, to: spaceOrigin)
                    }
                }
                .onEnded({ value in
                    self.model.targetTriangles = self.target.getTriangles(targetRotatingAngle: self.model.targetRotatingAngle)
                })
        )
        .gesture(
            SpatialTapGesture()
                .targetedToEntity(target.entity)
                .onEnded { value in
                    if !self.model.finishSetting{
                        rotate(entity: target.entity, axis: SIMD3<Float>(x: 0, y: 1, z: 0))
                        model.targetRotatingAngle = (model.targetRotatingAngle + 15) % 360
                        self.model.targetTriangles = self.target.getTriangles(targetRotatingAngle: self.model.targetRotatingAngle)
                    }
                }
        )
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { @MainActor drag in
                    if let object = self.model.objects.first(where: { $0.entity == drag.entity }), !self.model.finishSetting {
                        object.entity.position = drag.convert(drag.location3D, from: .local, to: spaceOrigin)
                    }
                }
        )
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { @MainActor tap in
                    if let object = self.model.objects.first(where: { $0.entity == tap.entity }), !self.model.finishSetting {
                        if let _ = object as? DartBoard{
                            rotate(entity: object.entity, axis: SIMD3<Float>(x: 0, y: 0, z: 1))
                        }
                        if let _ = object as? BasketballPanel{
                            rotate(entity: object.entity, axis: SIMD3<Float>(x: 0, y: 1, z: 0))
                        }
                    }
                }
        )
        .onAppear(perform: {
            self.reset(content: self.spaceOrigin)
        })
    }
    
    private func hasNan(fingers: [[SIMD3<Float>?]]) -> Bool {
        return fingers.first(where: {$0.contains { arr in
            return arr != nil && (arr!.x.isNaN || arr!.y.isNaN || arr!.z.isNaN)
        }}) != nil
    }
    
    private func handleUpdate(updateContent: RealityViewContent) {
        if let fingers = trackingModel.getAllHandPosition(), !hasNan(fingers: fingers){
            for i in 0..<self.fingerEntities.count{
                self.fingerEntities[i].position = fingers[Int(i/5)][i % 5]!
            }
            
            if let e = self.model.grabbingEntity {
                let now = Date()
                if now.timeIntervalSince(e.attachedTime) > 0.5 && distance(fingers[3][0]!, fingers[4][0]!) > 0.05{
                    e.attachedTime = now
                    e.entity.components[PhysicsBodyComponent.self]!.mode = .dynamic
                    self.model.grabbingEntity = nil
                }else{
                    e.entity.position = normalize(cross(fingers[0][4]! - fingers[3][3]!, fingers[1][3]! - fingers[3][3]!)) * 0.15 + fingers[1][3]!
                }
            }
            
            let (ray, triggerReleased, transform) = self.getCurrentGun().updatePosition(fingers: fingers, previousGunMatrix: self.model.previousGunMatrix)
            self.model.gunRay = ray
            self.model.previousGunMatrix.enqueue(transform)

            if(!self.model.finishSetting || !self.getCurrentGun().isHolding(fingers: fingers)){
                self.model.lastShootTime = nil
                self.model.gunTriggerReleased = true
            }else{
                if self.model.isReloading && (self.model.lastShootTime == nil || Date().timeIntervalSince(self.model.lastShootTime!) > 1){
                    startNewGame()
                }
                if triggerReleased {
                    self.model.gunTriggerReleased = true
                } else if !self.model.isReloading && (self.model.lastShootTime == nil || Date().timeIntervalSince(self.model.lastShootTime!) > 1.0 / Double(self.model.shootSpeed)) {
                    if self.model.gunTriggerReleased == true {
                        shoot()
                        self.model.gunTriggerReleased = false
                    }else if !self.model.singleShootMode {
                        shoot()
                    }
                    
                    if self.model.bulletCount == self.model.totalBullet {
                        self.getCurrentGun().playReloadSound()
                        self.model.isReloading = true
                    }
                }
            }
        }
    }
    
    private func startNewGame(){
        self.model.isReloading = false
        self.model.bulletCount = 0
        for h in self.holes {
            h.position = SIMD3(x: 0, y: 0, z: 0)
        }
        self.model.totalScore = 0
    }

    private func shoot(){
        if self.model.bulletCount >= self.model.totalBullet{
            return
        }
        if self.getCurrentGun().gunType == .portalGun && self.model.portals.count > 1{
            return
        }
        self.model.lastShootTime = Date()
        let currentBulletCount = self.model.bulletCount
        self.getCurrentGun().playShootSound()
        self.model.bulletCount = currentBulletCount + 1
        if let ray = self.model.gunRay, self.model.targetTriangles.count > 0 {
            if let p = intersect(ray: ray) {
                let score = self.target.getScore(hit: p)
                self.model.totalScore = self.model.totalScore + score
                self.holes[self.model.bulletCount-1].position = p
            }
            shootBullet(ray: ray)
        }
    }
    
    func shootBullet(ray: Ray) {
        let bulletType = self.getCurrentGun().bulletType
        let bullet = switch bulletType {
            case .ball: BallBullet(
                ray: ray,
                hitAllSound: self.model.soundResource.ballHitSound
            )
            case .jinxsBullet: JinxsBullet(
                ray: ray,
                jinxsBullet: self.model.bulletResource.jinxsBullet!,
                hitMetalSound: self.model.soundResource.metalHitMetalSound,
                hitWallSound: self.model.soundResource.metalHitWallSound,
                hitTargetSound: self.model.soundResource.metalHitTargetSound
            )
            case .pepsi: PepsiBullet(
                ray: ray,
                pepsiBullet: self.model.bulletResource.pepsi!,
                hitMetalSound: self.model.soundResource.metalHitMetalSound
            )
            case .metalBall: MetalBallBullet(
                ray: ray,
                metalBallBullet: self.model.bulletResource.metalBall!,
                hitMetalSound: self.model.soundResource.metalHitMetalSound,
                hitWallSound: self.model.soundResource.metalHitWallSound,
                hitTargetSound: self.model.soundResource.metalHitTargetSound
            )
            case .portalBullet: PortalBullet(
                ray: ray,
                portalBullet: self.model.bulletResource.portal!,
                teleportSound: self.model.soundResource.teleportSound
            )
            case .dart: DartBullet(
                ray: ray,
                dartBullet: self.model.bulletResource.dart!,
                hitMetalSound: self.model.soundResource.dartSound
            )
            case .basketball: BasketballBullet(
                ray: ray,
                basketballBullet: self.model.bulletResource.basketball!,
                basketballSound: self.model.soundResource.basketballSound
            )
        case .arrow: ArrowBullet(
            ray: ray,
            arrowBullet: self.model.bulletResource.arrow!,
            arrowSound: self.model.soundResource.arrowHitSound
            )
        }
        
        if bulletType == .portalBullet{
            self.model.portals.insert(bullet as! PortalBullet)
        }else{
            self.model.bullets.insert(bullet)
        }
        spaceOrigin.addChild(bullet.entity)
    }
    
    private func rotate(entity: Entity, axis: SIMD3<Float>) {
        let newOri = (entity.orientation(relativeTo: spaceOrigin) * simd_quatf(angle: Float(Float.pi / 12), axis: axis)).normalized
        entity.setOrientation(newOri, relativeTo: spaceOrigin)
    }
  
    private func intersect(ray: Ray) -> SIMD3<Float>? {
        if !self.target.entity.isEnabled{
            return nil
        }
        var values = [Float]()
        for tri in self.model.targetTriangles {
            if let t = tri.intersect(ray: ray){
                values.append(t)
                if values.count == 2 {
                    break
                }
            }
        }
        if values.isEmpty {
            return nil
        }
        return ray.origin + ray.direction * values.min()!
    }

    private func loadResource(content: RealityViewContent) async {
        do{
            let scene = try await Entity(named: "Immersive", in: realityKitContentBundle)
            content.add(scene)
                    
            if let gunShootSound = try? await AudioFileResource(named: "/Root/Sound/shoot_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let gunReloadSound = try? await AudioFileResource(named: "/Root/Sound/reload_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let teleportSound = try? await AudioFileResource(named: "/Root/Sound/teleport_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let metalHitMetalSound = try? await AudioFileResource(named: "/Root/Sound/metal_metal_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let metalHitWallSound = try? await AudioFileResource(named: "/Root/Sound/metal_wall_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let metalHitTargetSound = try? await AudioFileResource(named: "/Root/Sound/metal_target_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let ballHitSound = try? await AudioFileResource(named: "/Root/Sound/ball_all_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let dartSound = try? await AudioFileResource(named: "/Root/Sound/dart_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let arrowHitSound = try? await AudioFileResource(named: "/Root/Sound/arrow_hit_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let bowShootSound = try? await AudioFileResource(named: "/Root/Sound/bow_shoot_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let dartShootSound = try? await AudioFileResource(named: "/Root/Sound/dart_shoot_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let laserShootSound = try? await AudioFileResource(named: "/Root/Sound/laser_shoot_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let toyShootSound = try? await AudioFileResource(named: "/Root/Sound/toy_shoot_wav", from: "Immersive.usda", in: realityKitContentBundle),
               let basketballSound = try? await AudioFileResource(named: "/Root/Sound/basketball_wav", from: "Immersive.usda", in: realityKitContentBundle){
                self.model.soundResource.shootSound = gunShootSound
                self.model.soundResource.reloadSound = gunReloadSound
                self.model.soundResource.ballHitSound = ballHitSound
                self.model.soundResource.metalHitMetalSound = metalHitMetalSound
                self.model.soundResource.metalHitWallSound = metalHitWallSound
                self.model.soundResource.metalHitTargetSound = metalHitTargetSound
                self.model.soundResource.teleportSound = teleportSound
                self.model.soundResource.dartSound = dartSound
                self.model.soundResource.basketballSound = basketballSound
                self.model.soundResource.arrowHitSound = arrowHitSound
                self.model.soundResource.dartShootSound = dartShootSound
                self.model.soundResource.laserShootSound = laserShootSound
                self.model.soundResource.bowShootSound = bowShootSound
                self.model.soundResource.toyShootSound = toyShootSound

                await self.model.loadResource(scene: scene)
                for g in self.model.guns{
                    self.spaceOrigin.addChild(g.entity)
                }
                
                self.target.load()
                content.add(self.target.entity)
                self.model.targetTriangles = self.target.getTriangles(targetRotatingAngle: self.model.targetRotatingAngle)
                self.model.boxStatus = .Ready
                
                let sub = content.subscribe(to: CollisionEvents.Began.self, on: nil, handleCollision)
                self.subscriptions.append(sub)
                
                self.reset(content: spaceOrigin)
                self.model.resourceLoaded = true
            }
        } catch {
            fatalError("\tEncountered fatal error: \(error.localizedDescription)")
        }
    }
    
    private func handleCollision(event: CollisionEvents.Began){
        func handle(bulletEntity: Entity, another: Entity){
            if let bullet = self.model.bullets.first(where: { $0.entity == bulletEntity}){
                bullet.handleCollision(targetEntity: another, targetName: another.name)
                let now = Date()
                if let basketballBullet = bullet as? BasketballBullet, now.timeIntervalSince(basketballBullet.attachedTime) > 0.5, another.name.contains("left_hand_") && self.model.grabbingEntity == nil {
                    self.model.grabbingEntity = basketballBullet
                    basketballBullet.attachedTime = now
                    bullet.entity.components[PhysicsBodyComponent.self]!.mode = .static
                }
            } else if let portal = self.model.portals.first(where: { $0.entity == bulletEntity}){
                portal.handleCollision(targetEntity: another, targetName: another.name)

                if another.name != "Wall" && self.model.portals.count == 2 && portal.isReady && Date().timeIntervalSince(portal.lastUsedTime) > portal.waitTime{
                    
                    let anotherPortal = self.model.portals.first { $0 != portal }!
                    portal.lastUsedTime = Date()
                    anotherPortal.lastUsedTime = Date()
                    another.position = anotherPortal.entity.position + event.impulseDirection*0.02
                    
                    if let e = (another as? HasPhysics){
                        e.physicsMotion!.linearVelocity = -e.physicsMotion!.linearVelocity
                    }
                }
            }
        }
        let firstEntity = event.entityA
        let secondEntity = event.entityB
        
        if firstEntity.name.contains("Bullet"){
            handle(bulletEntity: firstEntity, another: secondEntity)
        }
        
        if secondEntity.name.contains("Bullet"){
            handle(bulletEntity: secondEntity, another: firstEntity)
        }
    }
    
    private func reset(content: Entity){
        self.model.reset()
        
        self.holes = []
        for i in 0..<self.model.totalBullet{
            self.holes.append(ModelEntity(mesh: .generateSphere(radius: 0.005), materials: [SimpleMaterial(color: UIColor(.red), isMetallic: true)]))
            content.addChild(self.holes[i])
        }
        updateGun()
    }
    
    private func updateGun(){
        for g in self.model.guns{
            if g.gunType != self.model.gunType{
                g.hide()
            }else{
                g.show()
                if self.bulletCountView != nil{
                    self.bulletCountView.removeFromParent()
                    g.entity.addChild(self.bulletCountView)
                }
               
                self.model.reloadSoundEntity.removeFromParent()
                g.entity.addChild(self.model.reloadSoundEntity)
            }
        }
    }
    
    private func getCurrentGun() -> IGun{
        return self.model.guns.first { gun in
            gun.gunType == self.model.gunType
        }!
    }
    
    private func tryAddingBoxTarget(){
        if self.model.boxStatus != .Adding{
            return
        }
        self.target.entity.isEnabled = true
        self.model.boxStatus = .Added
    }
    
    private func addToy(){
        let basePosition = self.fingerEntities[15].position

        switch self.model.addingToy{
            case .Rocket:
                if let rocket1 = self.model.toyResource.rocket1,
                   let rocket2 = self.model.toyResource.rocket2,
                   let rocket3 = self.model.toyResource.rocket3{
                    let rockets = [rocket1, rocket2, rocket3]
                    for i in 0..<2{
                        for j in 0..<2{
                            let c = rockets.randomElement()!.clone(recursive: true)
                            c.position = SIMD3(x: basePosition.x-0.5 + Float(i)/2, y: 0, z: basePosition.z-1-Float(j)/2)
                            self.spaceOrigin.addChild(c)
                            self.model.toyEntities.insert(c)
                        }
                    }
                }
            case .Pepsi:
                if let p = self.model.toyResource.pepsi{
                    for i in 0..<4{
                        for j in 0..<4{
                            let c = p.clone(recursive: true)
                            c.position = SIMD3(x: basePosition.x + Float(i)/10, y: basePosition.y, z: basePosition.z-Float(j)/10)
                            self.spaceOrigin.addChild(c)
                            self.model.toyEntities.insert(c)
                        }
                    }
                }
            case .Duck:
                if let p = self.model.toyResource.duck{
                    for i in 0..<1{
                        for j in 0..<1{
                            let c = p.clone(recursive: true)
                            c.position = SIMD3(x: basePosition.x + Float(i)/3, y: basePosition.y, z: basePosition.z-Float(j)/3)
                            self.spaceOrigin.addChild(c)
                            self.model.toyEntities.insert(c)
                        }
                    }
                }
        case .DartBoard:
            if let p = self.model.toyResource.dartBoard{
                let c = p.clone(recursive: true)
                c.position = SIMD3(x: basePosition.x, y: basePosition.y, z: basePosition.z-0.5)
                self.spaceOrigin.addChild(c)
                self.model.objects.insert(DartBoard(entity: c))
            }
        case .BasketballPanel:
            if let p = self.model.toyResource.basketballPanel{
                let c = p.clone(recursive: true)
                c.position = SIMD3(x: basePosition.x, y: basePosition.y-1, z: basePosition.z-0.5)
                self.spaceOrigin.addChild(c)
                self.model.objects.insert(BasketballPanel(entity: c))
            }
        case .none: break
        }
        self.model.addingToy = nil
    }
    
    func openSettingView(){
        let goDown = FromToByAnimation<Transform>(
            name: "goDown",
            from: .init(scale: .init(repeating: 0), translation: self.settingView.position),
            to: .init(scale: .init(repeating: 1), translation: self.settingView.position),
            duration: 0.5,
            timing: .easeOut,
            bindTarget: .transform
        )

        let goDownAnimation = try! AnimationResource
            .generate(with: goDown)

        let animation = try! AnimationResource.sequence(with: [goDownAnimation])

        self.settingView.playAnimation(animation, transitionDuration: 0.5)
    }
    
    func createFingertip() -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateSphere(radius: 0.005),
            materials: [UnlitMaterial(color: .cyan)],
            collisionShape: .generateSphere(radius: 0.005),
            mass: 0.0)

        entity.components.set(PhysicsBodyComponent(mode: .kinematic))
        entity.components.set(OpacityComponent(opacity: 0.0))

        return entity
    }
}
