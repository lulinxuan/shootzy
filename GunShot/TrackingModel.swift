/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Hand tracking updates.
*/

import ARKit
import SwiftUI
import RealityKit

/// A model that contains up-to-date hand coordinate information.
@MainActor
class TrackingModel: ObservableObject, @unchecked Sendable {
    let session = ARKitSession()
    var handTracking = HandTrackingProvider()
    let sceneReconstruction = SceneReconstructionProvider()
    private var meshEntities = [UUID: ModelEntity]()
    
    @Published var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }
    
    func start() async {
        do {
            if dataProvidersAreSupported && isReadyToRun {
                print("ARKitSession starting.")
                try await session.run([handTracking, sceneReconstruction])
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    func processReconstructionUpdates(contentEntity: Entity) async {
        for await update in sceneReconstruction.anchorUpdates {
            let meshAnchor = update.anchor

            guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { continue }
            switch update.event {
            case .added:
                let entity = ModelEntity()
                entity.name = "Wall"
                entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                if let _ = getClasses(meshAnchor: meshAnchor),
                  let meshResource = getMeshResourceFromAnchor(meshAnchor: meshAnchor) {
                    let modelComponent = ModelComponent(mesh: meshResource, materials: [OcclusionMaterial()])
                    entity.components.set(modelComponent)
                }
                entity.physicsBody = PhysicsBodyComponent(material: .generate(restitution: 1), mode: .static)
                meshEntities[meshAnchor.id] = entity
                contentEntity.addChild(entity)
            case .updated:
                guard let entity = meshEntities[meshAnchor.id] else { continue }
                entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                entity.collision?.shapes = [shape]
            case .removed:
                meshEntities[meshAnchor.id]?.removeFromParent()
                meshEntities.removeValue(forKey: meshAnchor.id)
            }
        }
    }
    
    func publishHandTrackingUpdates() async {
        for await update in handTracking.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                
                // Publish updates only if the hand and the relevant joints are tracked.
                guard anchor.isTracked else { continue }
                
                // Update left hand info.
                if anchor.chirality == .left {
                    latestHandTracking.left = anchor
                } else if anchor.chirality == .right { // Update right hand info.
                    latestHandTracking.right = anchor
                }
            default:
                break
            }
        }
    }
    
    func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(let type, let status):
                if type == .handTracking && status != .allowed {
                    // Stop the game, ask the user to grant hand tracking authorization again in Settings.
                }
            default:
                print("Session event \(event)")
            }
        }
    }
  
    func getAllHandPosition() -> [[SIMD3<Float>?]]? {
        guard let rightHandAnchor = latestHandTracking.right, let leftHandAnchor = latestHandTracking.left,
              rightHandAnchor.isTracked && leftHandAnchor.isTracked else {
            return nil
        }
        
        func getLeftHandPosition(joint: HandSkeleton.Joint?) -> SIMD3<Float>? {
            return (joint != nil) ?  getPosition(anchor: leftHandAnchor, joint: joint!) : nil
        }
        
        func getRightHandPosition(joint: HandSkeleton.Joint?) -> SIMD3<Float>? {
            return (joint != nil) ?  getPosition(anchor: rightHandAnchor, joint: joint!) : nil
        }

        
        func getPosition(anchor: HandAnchor, joint: HandSkeleton.Joint) -> SIMD3<Float> {
            matrix_multiply(
                anchor.originFromAnchorTransform, joint.anchorFromJointTransform
            ).columns.3.xyz
        }
        
        let leftHandLittleFinger: [SIMD3<Float>?] = [getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.littleFingerTip)),
                                                     getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.littleFingerIntermediateTip)),
                                                     getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.littleFingerIntermediateBase)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.littleFingerKnuckle)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.littleFingerMetacarpal))]
        
        let leftHandRingFinger: [SIMD3<Float>?] = [getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.ringFingerTip)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.ringFingerIntermediateTip)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.ringFingerIntermediateBase)),
                                                   getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.ringFingerKnuckle)),
                                                   getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.ringFingerMetacarpal))]
        
        let leftHandMiddleFinger: [SIMD3<Float>?] = [getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.middleFingerTip)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.middleFingerIntermediateTip)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.middleFingerIntermediateBase)),
                                                     getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.middleFingerKnuckle)),
                                                     getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.middleFingerMetacarpal))]
        
        let leftHandIndexFinger: [SIMD3<Float>?] = [getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.indexFingerTip)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.indexFingerIntermediateTip)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.indexFingerIntermediateBase)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.indexFingerKnuckle)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.indexFingerMetacarpal))]
        
        let leftHandThumbFinger: [SIMD3<Float>?] = [getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.thumbTip)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.thumbIntermediateTip)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.thumbIntermediateBase)),
                                                    getLeftHandPosition(joint: leftHandAnchor.handSkeleton?.joint(.thumbKnuckle)),
                                                    nil]
        
        let rightHandLittleFinger: [SIMD3<Float>?] = [getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.littleFingerTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.littleFingerIntermediateTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.littleFingerIntermediateBase)),
                                                      getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.littleFingerKnuckle)),
                                                      getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.littleFingerMetacarpal)),]
        
        let rightHandRingFinger: [SIMD3<Float>?] = [getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.ringFingerTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.ringFingerIntermediateTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.ringFingerIntermediateBase)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.ringFingerKnuckle)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.ringFingerMetacarpal)),]
        
        let rightHandMiddleFinger: [SIMD3<Float>?] = [getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.middleFingerTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.middleFingerIntermediateTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.middleFingerIntermediateBase)),
                                                      getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.middleFingerKnuckle)),
                                                      getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.middleFingerMetacarpal))]
        
        let rightHandIndexFinger: [SIMD3<Float>?] = [getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.indexFingerTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.indexFingerIntermediateTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.indexFingerIntermediateBase)),
                                                     getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.indexFingerKnuckle)),
                                                     getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.indexFingerMetacarpal))]
        
        let rightHandThumbFinger: [SIMD3<Float>?] = [getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.thumbTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.thumbIntermediateTip)),
                                                    getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.thumbIntermediateBase)),
                                                     getRightHandPosition(joint: rightHandAnchor.handSkeleton?.joint(.thumbKnuckle)),
                                                     nil]
        return [leftHandLittleFinger, leftHandRingFinger, leftHandMiddleFinger, leftHandIndexFinger, leftHandThumbFinger, rightHandLittleFinger, rightHandRingFinger, rightHandMiddleFinger, rightHandIndexFinger, rightHandThumbFinger]
    }
    
    var dataProvidersAreSupported: Bool {
        HandTrackingProvider.isSupported && SceneReconstructionProvider.isSupported
    }
    
    var isReadyToRun: Bool {
        handTracking.state == .initialized && sceneReconstruction.state == .initialized
    }
    
    private func getClasses(meshAnchor: MeshAnchor) -> [UInt8]? {
      guard let classifications = meshAnchor.geometry.classifications,
            classifications.format == .uchar else { return nil }
      
      let classBuffer = classifications.buffer.contents()
      let classTyped = classBuffer.bindMemory(to: UInt8.self, capacity: MemoryLayout<UInt8>.stride * classifications.count)
      
      let classBufferPointer = UnsafeBufferPointer(start: classTyped, count: classifications.count)
      return Array(classBufferPointer)
    }
    
    private func getMeshResourceFromAnchor(meshAnchor: MeshAnchor, classes: [UInt8]? = nil) -> MeshResource? {
      guard meshAnchor.geometry.faces.primitive == .triangle,
            meshAnchor.geometry.vertices.format == .float3,
            let indexArray = getIndexArray(meshAnchor: meshAnchor) else {
              return nil
            }
      
      var contents = MeshResource.Contents()
      var part = MeshResource.Part(id: "part", materialIndex: 0)
      
      let positions = readFloat3FromMTL(source: meshAnchor.geometry.vertices)
      
      var resultIndexArray:[UInt32] = indexArray
      
      if let classes = classes {
        resultIndexArray = []
        for faceId in 0 ..< meshAnchor.geometry.faces.count {
          let classId = classes[faceId]
          //floor
          if classId == 2 {
            let v0:UInt32 = indexArray[faceId * 3]
            let v1:UInt32 = indexArray[faceId * 3 + 1]
            let v2:UInt32 = indexArray[faceId * 3 + 2]
            
            resultIndexArray.append(v0)
            resultIndexArray.append(v1)
            resultIndexArray.append(v2)
          }
        }
      }
      
      part.triangleIndices = MeshBuffer(resultIndexArray)
      part.positions = MeshBuffer(positions)
      
      let model = MeshResource.Model(id: "main", parts: [part])
      contents.models = [model]
      
      contents.instances = [.init(id: "instance", model: "main")]
      if let meshResource = try? MeshResource.generate(from: contents) {
        return meshResource
      }
      return nil
    }
    
    private func getIndexArray(meshAnchor: MeshAnchor) -> [UInt32]? {
      let indexBufferRawPointer = meshAnchor.geometry.faces.buffer.contents()
      
      let numIndices = meshAnchor.geometry.faces.count * 3
      
      let typedPointer = indexBufferRawPointer.bindMemory(to: UInt32.self, capacity: meshAnchor.geometry.faces.bytesPerIndex * numIndices)
      
      let indexBufferPointer = UnsafeBufferPointer(start: typedPointer, count: numIndices)
      return Array(indexBufferPointer)
    }
    
    private func readFloat3FromMTL(source: GeometrySource) -> [SIMD3<Float>] {
      var result:[SIMD3<Float>] = []
      
      let pointer = source.buffer.contents()
      for i in 0 ..< source.count {
        let dataPointer = pointer + source.offset + i * source.stride
        
        let pointer = dataPointer.bindMemory(to: SIMD3<Float>.self, capacity: MemoryLayout<SIMD3<Float>>.stride)
        result.append(pointer.pointee)
      }
      
      return result
    }
    
}

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension ModelEntity {
    /// Creates an invisible sphere that can interact with dropped cubes in the scene.
    class func createFingertip() -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateSphere(radius: 0.005),
            materials: [UnlitMaterial(color: .cyan)],
            collisionShape: .generateSphere(radius: 0.005),
            mass: 0.0)

        entity.components.set(PhysicsBodyComponent(mode: .kinematic))
//        entity.components.set(OpacityComponent(opacity: 0.0))

        return entity
    }
}
