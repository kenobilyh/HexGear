//
//  CodeFormat.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/11.
//

import SwiftUI

// 支援的程式碼輸出格式
enum CodeFormat: String, CaseIterable, Identifiable {
    case swiftUI = "SwiftUI"
    case uiKit = "UIKit"
    case css = "CSS"
    case kotlin = "Kotlin"
    case compose = "Compose"
    
    var id: String { self.rawValue }
    
    var label: String {
        switch self {
        case .swiftUI: return "SwiftUI (Color)"
        case .uiKit: return "UIKit (UIColor)"
        case .css: return "CSS (RGB)"
        case .kotlin: return "Android (Color.rgb)"
        case .compose: return "Jetpack Compose"
        }
    }
}

// 產生程式碼字串
func generateCode(format: CodeFormat, color: Color) -> String {
    let rgb = color.rgbValues
    let r = rgb.r
    let g = rgb.g
    let b = rgb.b
    
    // 0.0-1.0 float strings
    let rf = String(format: "%.3g", Double(r)/255.0)
    let gf = String(format: "%.3g", Double(g)/255.0)
    let bf = String(format: "%.3g", Double(b)/255.0)
    
    switch format {
    case .css:
        return "rgb(\(r), \(g), \(b))"
    case .swiftUI:
        return "Color(red: \(rf), green: \(gf), blue: \(bf))"
    case .uiKit:
        return "UIColor(red: \(rf), green: \(gf), blue: \(bf), alpha: 1.0)"
    case .kotlin:
        return "Color.rgb(\(r), \(g), \(b))"
    case .compose:
        let hex = color.toHex()?.replacingOccurrences(of: "#", with: "") ?? "000000"
        return "Color(0xFF\(hex))"
    }
}
