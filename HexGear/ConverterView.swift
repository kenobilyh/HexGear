//
//  ConverterView.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/11.
//

import SwiftUI

// MARK: - 3. 轉換器視圖 (Converter View)

struct ConverterView: View {
    @Binding var history: [Color]
    @Binding var codeFormat: CodeFormat
    
    @State private var selectedColor: Color = Color(hex: "#3B82F6")!
    @State private var hexInput: String = "#3B82F6"
    @State private var copyFeedback: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. 大型預覽與吸管
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(selectedColor)
                    .frame(height: 140)
                    .cornerRadius(12)
                    .overlay(alignment: .topTrailing) {
                        // 亮度標籤
                        HStack(spacing: 4) {
                            Image(systemName: selectedColor.isLight ? "sun.max.fill" : "moon.fill")
                            Text("\(selectedColor.isLight ? NSLocalizedString("light", comment: "") : NSLocalizedString("dark", comment: "")) (\(selectedColor.brightnessScore))")
                        }
                        .font(.caption.bold())
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                        .padding(8)
                        .foregroundColor(selectedColor.isLight ? .black : .white)
                    }
                
                // 原生 ColorPicker (自帶吸管功能)
                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .padding(10)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
                    .padding(8)
                    .onChange(of: selectedColor, { _, newValue in
                        updateHexFromColor(newValue)
                        addToHistory(newValue)
                    })
            }
            .shadow(radius: 2, y: 1)
            
            // 2. 歷史紀錄
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(LocalizedStringKey("history"), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(history, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                .onTapGesture {
                                    selectedColor = color
                                    updateHexFromColor(color)
                                }
                        }
                    }
                    .padding(2)
                }
            }
            
            Divider()
            
            // 3. Hex 輸入
            GroupBox {
                HStack {
                    Text("#")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                    TextField("HEX", text: $hexInput)
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.plain)
                        .onChange(of: hexInput) { _, newValue in
                            if let newColor = Color(hex: newValue) {
                                selectedColor = newColor
                            }
                        }
                    
                    Button {
                        copyToClipboard(hexInput)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                }
                .padding(6)
            } label: {
                Text(LocalizedStringKey("hex_code")).font(.caption).foregroundColor(.secondary)
            }
            
            // 4. RGB 數值顯示 (簡化顯示)
            let rgb = selectedColor.rgbValues
            HStack(spacing: 10) {
                RGBField(label: "R", value: rgb.r)
                RGBField(label: "G", value: rgb.g)
                RGBField(label: "B", value: rgb.b)
            }
            
            Spacer()
            
            Divider()
            
            // 5. 程式碼輸出與設定
            CodeOutputView(format: $codeFormat, color: selectedColor)
        }
        .padding()
    }
    
    // Helper Functions
    func updateHexFromColor(_ color: Color) {
        if let hex = color.toHex() {
            hexInput = hex
        }
    }
    
    func addToHistory(_ color: Color) {
        // 簡單去重並保持長度
        if let index = history.firstIndex(of: color) {
            history.remove(at: index)
        }
        history.insert(color, at: 0)
        if history.count > 7 {
            history = Array(history.prefix(7))
        }
    }
    
    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        // 這裡可以加入複製成功的動畫邏輯
    }
}
