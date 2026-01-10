//
//  BlenderView.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/11.
//

import SwiftUI

// MARK: - 4. 混色器視圖 (Blender View)

struct BlenderView: View {
    @Binding var codeFormat: CodeFormat
    
    @State private var fgColor: Color = .white
    @State private var bgColor: Color = Color(hex: "#3B82F6")!
    @State private var opacity: Double = 100.0
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. 視覺化預覽 (ZStack 疊加)
            ZStack {
                Rectangle()
                    .fill(bgColor)
                
                Circle()
                    .fill(fgColor)
                    .opacity(opacity / 100.0)
                    .frame(width: 100, height: 100)
                    .shadow(radius: 5)
                    .overlay {
                        Text("FG \(Int(opacity))%")
                            .font(.caption2.bold())
                            .padding(4)
                            .background(.black.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("BG")
                            .font(.caption.monospaced())
                            .padding(4)
                            .background(.white.opacity(0.6))
                            .cornerRadius(4)
                            .padding(8)
                    }
                }
            }
            .frame(height: 150)
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // 2. 顏色選擇器
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey("foreground_label")).font(.caption).foregroundColor(.secondary)
                    ColorPicker(LocalizedStringKey("foreground"), selection: $fgColor)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey("background_label")).font(.caption).foregroundColor(.secondary)
                    ColorPicker(LocalizedStringKey("background"), selection: $bgColor)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 3. 透明度滑桿
            VStack(alignment: .leading) {
                HStack {
                    Label(LocalizedStringKey("opacity"), systemImage: "slider.horizontal.3").font(.caption)
                    Spacer()
                    Text("\(Int(opacity))%").font(.caption.monospaced())
                }
                Slider(value: $opacity, in: 0...100, step: 1)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // 4. WCAG 對比度與混色結果
            // 注意：SwiftUI 沒有直接的「混色後 Color」，我們需要手動計算 RGB
            let blended = blendColors(fg: fgColor, bg: bgColor, alpha: opacity / 100.0)
            let contrast = WCAGLogic.calculateContrast(blended, bgColor)
            let compliance = WCAGLogic.checkCompliance(ratio: contrast)
            
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        Label(LocalizedStringKey("wcag_contrast"), systemImage: "scale.3d").font(.caption.bold())
                        Spacer()
                        Text(String(format: "%.2f : 1", contrast))
                            .font(.title2.bold())
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        StatusBadge(pass: compliance.aaNormal, label: "AA Normal")
                        StatusBadge(pass: compliance.aaLarge, label: "AA Large")
                        StatusBadge(pass: compliance.aaaNormal, label: "AAA Normal")
                        StatusBadge(pass: compliance.aaaLarge, label: "AAA Large")
                    }
                }
                .padding(4)
            }
            
            Spacer()
            Divider()
            
            // 5. 輸出
            CodeOutputView(format: $codeFormat, color: blended)
        }
        .padding()
    }
    
    // 手動混色算法
    func blendColors(fg: Color, bg: Color, alpha: Double) -> Color {
        let f = fg.rgbValues
        let b = bg.rgbValues
        
        let r = Double(f.r) * alpha + Double(b.r) * (1 - alpha)
        let g = Double(f.g) * alpha + Double(b.g) * (1 - alpha)
        let bl = Double(f.b) * alpha + Double(b.b) * (1 - alpha)
        
        return Color(red: r/255.0, green: g/255.0, blue: bl/255.0)
    }
}
