//
//  Triangle.swift
//  GunShot
//
//  Created by Linxuan Lu on 13/3/24.
//

import Foundation
import RealityKit

struct Triangle {
    var vertex0: SIMD3<Float>
    var vertex1: SIMD3<Float>
    var vertex2: SIMD3<Float>
    
    func intersect(ray: Ray) -> Float? {
        let epsilon: Float = 0.000001

        let edge1 = self.vertex1 - self.vertex0
        let edge2 = self.vertex2 - self.vertex0
        let h = simd_cross(ray.direction, edge2)

        let a = simd_dot(edge1, h)

        if a > -epsilon && a < epsilon {
            return nil
        }

        let f = 1.0 / a
        let s = ray.origin - self.vertex0
        let u = f * simd_dot(s, h)

        if u < 0.0 || u > 1.0 {
            return nil
        }

        let q = simd_cross(s, edge1)
        let v = f * simd_dot(ray.direction, q)

        if v < 0.0 || u + v > 1.0 {
            return nil
        }

        let t = f * simd_dot(edge2, q)

        if t > epsilon {
            return t
        } else {
            return nil
        }
    }
}
