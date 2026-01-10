//
//  WCAGLogic.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/11.
//

import SwiftUI

// WCAG 對比度計算邏輯
struct WCAGLogic {
    static func getLuminance(_ color: Color) -> CGFloat {
        guard let components = color.cgColor?.components, components.count >= 3 else { return 0 }
        let values = [components[0], components[1], components[2]].map { v -> CGFloat in
            let val = v
            return val <= 0.03928 ? val / 12.92 : pow((val + 0.055) / 1.055, 2.4)
        }
        return values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722
    }
    
    static func calculateContrast(_ c1: Color, _ c2: Color) -> CGFloat {
        let l1 = getLuminance(c1)
        let l2 = getLuminance(c2)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }
    
    static func checkCompliance(ratio: CGFloat) -> (aaNormal: Bool, aaLarge: Bool, aaaNormal: Bool, aaaLarge: Bool) {
        return (ratio >= 4.5, ratio >= 3.0, ratio >= 7.0, ratio >= 4.5)
    }
}
