//
//  ConverterView.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/11.
//

import SwiftUI
import Combine

// MARK: - 3. 轉換器視圖 (Converter View)

struct ConverterView: View {
    @Binding var history: [Color]
    @Binding var codeFormat: CodeFormat
    
    @State private var selectedColor: Color = Color(hex: Self.defaultColorString)!
    @State private var hexInput = Self.defaultColorString
    @State private var copyFeedback: Bool = false
    @StateObject private var debouncer = HistoryDebouncer()
    private static let defaultColorString = "#3B82F6"
    
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
            }
            .shadow(radius: 2, y: 1)
            
            // 2. 歷史紀錄
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(LocalizedStringKey("recent"), systemImage: "clock")
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
                                    NSApp.keyWindow?.makeFirstResponder(nil)
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(2)
                }
            }
            
            Divider()
            
            // 3. Hex 輸入
            HStack {
            HexInputView(hexInput: $hexInput, selectedColor: $selectedColor)
                
                // 原生 ColorPicker (自帶吸管功能)
                ZStack {
                    ColorPicker("Pick a Color", selection: $selectedColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding(8)
                        .onChange(of: selectedColor) { _, newValue in
                            debouncer.input.send(newValue)
                        }
                        .onReceive(debouncer.$output) { color in
                            if let color {
                                addToHistory(color)
                            }
                        }
                    Image(systemName: "eyedropper")
                        .allowsHitTesting(false)
                }
            }
            
            // 4. RGB 數值顯示 (可編輯)
            HStack(spacing: 10) {
                RGBField(label: "R", value: Binding(
                    get: { Int(selectedColor.rgbValues.r) },
                    set: { updateColor(r: $0) }
                ))
                RGBField(label: "G", value: Binding(
                    get: { Int(selectedColor.rgbValues.g) },
                    set: { updateColor(g: $0) }
                ))
                RGBField(label: "B", value: Binding(
                    get: { Int(selectedColor.rgbValues.b) },
                    set: { updateColor(b: $0) }
                ))
            }
            
            Spacer()
            
            Divider()
            
            // 5. 程式碼輸出與設定
            CodeOutputView(format: $codeFormat, color: selectedColor)
        }
        .padding()
    }
    
    // Helper Functions
    func updateColor(r: Int? = nil, g: Int? = nil, b: Int? = nil) {
        let currentRGB = selectedColor.rgbValues
        let newR = r ?? currentRGB.r
        let newG = g ?? currentRGB.g
        let newB = b ?? currentRGB.b
        
        let newColor = Color(
            red: Double(newR) / 255.0,
            green: Double(newG) / 255.0,
            blue: Double(newB) / 255.0
        )
        selectedColor = newColor
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
    }
    
class HistoryDebouncer: ObservableObject {
    let input = PassthroughSubject<Color, Never>()
    @Published var output: Color?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        input
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] color in
                self?.output = color
            }
            .store(in: &cancellables)
    }
}

// preview
struct ConverterView_Previews: PreviewProvider {
    static var previews: some View {
        ConverterView(history: .constant([]), codeFormat: .constant(.swiftUI))
    }
}
