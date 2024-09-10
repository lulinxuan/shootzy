import RealityKit
import SwiftUI

@Observable
class IObject: Hashable{
    static func == (lhs: IObject, rhs: IObject) -> Bool {
        return lhs.entity == rhs.entity
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(entity)
    }
    
    var entity: Entity
    
    init(entity: Entity) {
        self.entity = entity
    }
}
