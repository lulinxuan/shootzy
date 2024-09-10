//
//  Extensions.swift
//  GunShot
//
//  Created by Linxuan Lu on 4/4/24.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
