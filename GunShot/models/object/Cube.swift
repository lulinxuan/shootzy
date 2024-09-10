import RealityKit
import SwiftUI

@Observable
class Cube{
    var entity = ModelEntity(
        mesh: .generateBox(size: 0.5, cornerRadius: 0),
        materials: [],
        collisionShape: .generateBox(size: SIMD3<Float>(repeating: 0.5)),
        mass: 0
    )
    var centers: [SIMD3<Float>] = []
    var totalScore = 0
    
    func load() {
        let resource = try? TextureResource.load(named: "target")
        var material = UnlitMaterial()
        material.color = .init(tint: .white ,texture: .init(resource!))
        
        self.entity.model!.materials = [material]
        self.entity.name = "cube"
        self.entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        
        let material_2 = PhysicsMaterialResource.generate(friction: 0.8, restitution: 0.0)
        self.entity.components.set(PhysicsBodyComponent(shapes: entity.collision!.shapes,
                                                   mass: 0.0,
                                                   material: material_2,
                                                   mode: .dynamic))
        self.entity.position = SIMD3(x: 0, y: 1, z: -1)
        
        entity.isEnabled = false
    }
    
    func getTriangles(targetRotatingAngle: Int) -> [Triangle]{
        let radius = Float(sqrt(0.125))
        let angle_1 = Float.pi*2*Float(targetRotatingAngle)/360
        let angle_2 = Float.pi*2*Float(targetRotatingAngle+90)/360

        let x_1 = radius * sin(angle_1)
        let x_2 = radius * sin(angle_2)
        let z_1 = radius * cos(angle_1)
        let z_2 = radius * cos(angle_2)
        let vertexes = [
            entity.position + SIMD3<Float>(x: x_1, y: 0.25, z: z_1),
            entity.position - SIMD3<Float>(x: x_1, y: 0.25, z: z_1),
            entity.position + SIMD3<Float>(x: x_2, y: 0.25, z: z_2),
            entity.position - SIMD3<Float>(x: x_2, y: 0.25, z: z_2),
            entity.position + SIMD3<Float>(x: x_1, y: -0.25, z: z_1),
            entity.position - SIMD3<Float>(x: x_1, y: -0.25, z: z_1),
            entity.position + SIMD3<Float>(x: x_2, y: -0.25, z: z_2),
            entity.position - SIMD3<Float>(x: x_2, y: -0.25, z: z_2)
        ]
        func t(a: Int, b: Int, c: Int) -> Triangle{
            return Triangle(vertex0: vertexes[a], vertex1: vertexes[b], vertex2: vertexes[c])
        }
        
        func center(a: Int, b: Int) -> SIMD3<Float>{
            return (vertexes[a] + vertexes[b]) / 2
        }

        self.centers = [
            center(a: 0, b: 3),
            center(a: 5, b: 3),
            center(a: 1, b: 2),
            center(a: 0, b: 6),
            center(a: 0, b: 5),
            center(a: 6, b: 3)
        ]
        
        return [
            t(a: 0, b: 2, c: 4),
            t(a: 2, b: 6, c: 4),
            t(a: 5, b: 2, c: 6),
            t(a: 1, b: 5, c: 6),
            t(a: 1, b: 3, c: 5),
            t(a: 3, b: 5, c: 7),
            t(a: 0, b: 3, c: 7),
            t(a: 0, b: 3, c: 4),
            t(a: 2, b: 5, c: 7),
            t(a: 0, b: 2, c: 7),
            t(a: 1, b: 6, c: 4),
            t(a: 1, b: 3, c: 4),
        ]
    }
    
    func getScore(hit: SIMD3<Float>) -> Float {
        let dis = self.centers.map { c in
            distance(hit, c) * 100
        }.min()!
        if dis >= 22{
            return 0.0
        } else{
            return 10 - (dis / 2.2)
        }
    }
}
