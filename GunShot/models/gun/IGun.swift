import RealityKit
import SwiftUI

@MainActor
class IGun{
    @State var entity = Entity()
    let zero = simd_matrix(SIMD4<Float>(0, 0, 0, 0), SIMD4<Float>(0, 0, 0, 0), SIMD4<Float>(0, 0, 0, 0), SIMD4<Float>(0, 0, 0, 0))
    let triggerAngle: Float
    let scale: Float
    let name: String
    let positionOffset: SIMD3<Float>
    let gunType: GunType
    let bulletType: BulletType
    let shootSound: AudioFileResource
    let reloadSound: AudioFileResource
    var shootSoundPlayIndex = 0
    var shootSoundControllers: [AudioPlaybackController] = []
    var reloadSoundController: AudioPlaybackController? = nil
    
    init(triggerAngle: Float, scale: Float, name: String, gunType: GunType, bulletType: BulletType, positionOffset: SIMD3<Float>, shootSound: AudioFileResource, reloadSound: AudioFileResource) {
        self.triggerAngle = triggerAngle
        self.scale = scale
        self.name = name
        self.positionOffset = positionOffset
        self.gunType = gunType
        self.bulletType = bulletType
        self.shootSound = shootSound
        self.reloadSound = reloadSound
    }
    
    func playShootSound(){
        if !self.shootSoundControllers.isEmpty{
            self.shootSoundControllers[self.shootSoundPlayIndex].play()
            self.shootSoundPlayIndex = (self.shootSoundPlayIndex + 1) % 10
        }
    }
    
    func playReloadSound(){
        self.reloadSoundController?.play()
    }

    func load(scene: Entity) async -> IGun {
        if let gunModel = scene.findEntity(named: self.name){
            await MainActor.run {
                gunModel.scale = SIMD3<Float>(repeating: self.scale)
                self.entity.name = self.name
                self.entity.addChild(gunModel)
                gunModel.position = positionOffset
                
                for _ in 0..<10{
                    let c = self.entity.prepareAudio(self.shootSound)
                    c.gain = -20
                    self.shootSoundControllers.append(c)
                }
                self.reloadSoundController = self.entity.prepareAudio(self.reloadSound)
                self.reloadSoundController?.gain = -20
            }
        }
        return self
    }
    
    func isHolding(fingers: [[SIMD3<Float>?]]) -> Bool {
        return true
    }
    
    func updatePosition(fingers: [[SIMD3<Float>?]], previousGunMatrix: FixedSizeQueue<simd_float4x4>) -> (Ray, Bool, simd_float4x4) {
        let zAxis = normalize(fingers[6][4]! - fingers[6][3]!)
        let yAxis = normalize(fingers[7][3]! - fingers[5][3]!)
        let xAxis = -cross(zAxis, yAxis)
        
        let midPosition = fingers[7][3]! - 0.04*xAxis
        
        let transform = simd_matrix(
            SIMD4(xAxis.x, xAxis.y, xAxis.z, 0),
            SIMD4(yAxis.x, yAxis.y, yAxis.z, 0),
            SIMD4(zAxis.x, zAxis.y, zAxis.z, 0),
            SIMD4(midPosition.x, midPosition.y, midPosition.z, 1)
        )
        
        if !transform.columns.0.x.isNaN{
            previousGunMatrix.enqueue(transform)
        }
        
        let average = self.getAverageGunMatrix(previousGunMatrix: previousGunMatrix)
        
        let position = Pose3D(average)!.position
        let rotation = Pose3D(average)!.rotation
        
        self.entity.transform.translation = SIMD3<Float>(position.vector)
        self.entity.transform.rotation = simd_quatf(vector: [Float(rotation.vector.x), Float(rotation.vector.y), Float(rotation.vector.z), Float(rotation.vector.w)])
        
        let ray = Ray(origin: average[3].xyz + 0.09*average[1].xyz, direction: -average[2].xyz-0.06*average[1].xyz)
        
        let vector1 = fingers[8][1]! - fingers[8][2]!
        let vector2 = fingers[8][2]! - fingers[8][3]!
        let cosineTheta = simd_dot(vector1, vector2) / (simd_length(vector1) * simd_length(vector2))
        // Clamp the cosine value to [-1, 1] to avoid NaN when using acos
        let safeCosineTheta = max(-1.0, min(1.0, cosineTheta))
        // Calculate the angle in radians
        let theta = acos(safeCosineTheta)

        return (ray, theta * 180 / Float.pi < triggerAngle, transform)
    }
    
    private func getAverageGunMatrix(previousGunMatrix: FixedSizeQueue<simd_float4x4>) -> simd_float4x4 {
        let previous = previousGunMatrix.values
        let sum = previous.reduce(zero, +)
        let count = Float(previous.count)
        return simd_float4x4(columns: (sum.columns.0 / count, sum.columns.1 / count, sum.columns.2 / count, sum.columns.3 / count))
    }
    
    func hide(){
        if self.entity.isEnabled{
            self.entity.isEnabled = false
        }
    }
    
    func show(){
        if !self.entity.isEnabled{
            self.entity.isEnabled = true
        }
    }
}
