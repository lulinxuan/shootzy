//
//  MenuItem.swift
//  MusicPlayerUI-VisionOS
//
//  Created by Vinoth Vino on 22/07/23.
//

import Foundation

struct SettingMenuItem: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let icon: String
    
    static func getMenuItems() -> [SettingMenuItem] {
        return [
            SettingMenuItem(label: "Targets", icon: "camera.filters"),
            SettingMenuItem(label: "Gun", icon: "scope"),
        ]
    }
}
