//
//  Color+Extensions.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/11.
//

import SwiftUI

// 色彩工具擴充
extension Color {
    // 從 Hex 字串初始化
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    // 轉回 Hex 字串
    func toHex(includeAlpha: Bool = false) -> String? {
        guard let components = cgColor?.components, components.count >= 3 else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if includeAlpha {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
    
    // 計算亮度 (W3C AERT)
    var brightnessScore: Int {
        guard let components = cgColor?.components, components.count >= 3 else { return 0 }
        let r = components[0] * 255
        let g = components[1] * 255
        let b = components[2] * 255
        return Int(((r * 299) + (g * 587) + (b * 114)) / 1000)
    }
    
    var isLight: Bool {
        return brightnessScore > 128
    }
    
    // 獲取 RGB 整數值
    var rgbValues: (r: Int, g: Int, b: Int) {
        guard let components = cgColor?.components, components.count >= 3 else { return (0,0,0) }
        return (Int(components[0] * 255), Int(components[1] * 255), Int(components[2] * 255))
    }
}
