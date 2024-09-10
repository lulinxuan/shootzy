import ARKit
import RealityKit
import SwiftUI

@Observable
class IBullet: Hashable {
    var entity: Entity! = nil
    var creationTime = Date()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(creationTime)
    }
    
    static func == (lhs: IBullet, rhs: IBullet) -> Bool {
        return lhs.creationTime == rhs.creationTime
    }
    
    func handleCollision(targetEntity: Entity, targetName: String){}
}
