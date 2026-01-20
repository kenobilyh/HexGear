//
//  ImagePaletteView.swift
//  HexGear
//
//  Created by HexGear Agent on 2026/1/17.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

// MARK: - Algorithm Result Model
struct PaletteResult: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let hex: String
    let description: String
}

// MARK: - View
struct ImagePaletteView: View {
    @State private var inputImage: NSImage?
    @State private var results: [PaletteResult] = []
    @State private var isDragging = false
    @State private var selectedResultId: UUID?
    @State private var applyBackground = true
    @Binding var codeFormat: CodeFormat
    
    // Default selecting the first one or logic
    private var selectedColor: Color {
        if let id = selectedResultId, let res = results.first(where: { $0.id == id }) {
            return res.color
        }
        return results.first?.color ?? .clear
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. Drag & Drop Zone
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isDragging ? Color.blue : Color.gray.opacity(0.3), lineWidth: isDragging ? 3 : 2)
                        .background(applyBackground && !results.isEmpty ? selectedColor : Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(height: 200)
                    
                    if let img = inputImage {
                        ZStack(alignment: .topTrailing) {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180) // Slightly smaller to show background if applied
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(10)
                            
                            Button {
                                withAnimation {
                                    reset()
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white, .gray)
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(.plain)
                            .padding(8)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text(LocalizedStringKey("drag_drop_image"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button {
                                pasteFromClipboard()
                            } label: {
                                Label(LocalizedStringKey("paste_image"), systemImage: "doc.on.clipboard")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
                .onDrop(of: [UTType.image], isTargeted: $isDragging) { providers in
                    loadContent(from: providers)
                }
                
                Toggle("Apply selected color to background", isOn: $applyBackground)
                    .toggleStyle(.checkbox)
                    .disabled(results.isEmpty)
            }
            
            Divider()
            
            // 2. Results Grid
            if results.isEmpty {
                VStack {
                    Text(LocalizedStringKey("no_colors_extracted"))
                        .foregroundColor(.secondary)
                        .italic()
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack {
                    HStack {
                        Label(LocalizedStringKey("recommended_backgrounds"), systemImage: "paint.bucket.classic").font(.caption.bold())
                        Spacer()
                    }
                    ScrollView {
                        HStack(spacing: 20) {
                            ForEach(results) { res in
                                ResultCard(result: res, isSelected: selectedResultId == res.id)
                                    .onTapGesture {
                                        selectedResultId = res.id
                                    }
                            }
                        }.padding()
                    }
                }
            }
            
            Divider()
            
            // 3. Code Output
            if !results.isEmpty {
                CodeOutputView(format: $codeFormat, color: selectedColor)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .animation(.spring(), value: results.count)
    }
}

extension ImagePaletteView {
    // MARK:Logic
    
    private func loadContent(from providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.canLoadObject(ofClass: NSImage.self) {
            provider.loadObject(ofClass: NSImage.self) { image, error in
                guard let nsImage = image as? NSImage else { return }
                DispatchQueue.main.async {
                    self.performAnalysis(nsImage)
                }
            }
            return true
        }
        return false
    }
    
    private func pasteFromClipboard() {
        let pb = NSPasteboard.general
        if pb.canReadObject(forClasses: [NSImage.self], options: nil),
           let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
           let first = images.first {
            performAnalysis(first)
        }
    }
    
    private func performAnalysis(_ image: NSImage) {
        inputImage = image
        results = []
        
        // Run specific algorithms
        
        // 1. CIAreaAverage
        if let c1 = ColorExtractor.extractAreaAverage(from: image) {
            let hex = c1.toHex() ?? "N/A"
            results.append(PaletteResult(name: "CIAreaAverage", color: c1, hex: hex, description: "Average"))
        }
        
        // 2. Scale 1x1
        if let c2 = ColorExtractor.extractScaled1x1(from: image) {
            let hex = c2.toHex() ?? "N/A"
            results.append(PaletteResult(name: "Scale to 1x1", color: c2, hex: hex, description: "Resized"))
        }
        
        // 3. CIAreaHistogram
        if let c3 = ColorExtractor.extractHistogramDominant(from: image) {
            let hex = c3.toHex() ?? "N/A"
            results.append(PaletteResult(name: "CIAreaHistogram", color: c3, hex: hex, description: "Dominant"))
        }
        
        // Auto select first
        self.selectedResultId = results.first?.id
    }
    
    private func reset() {
        self.inputImage = nil
        self.results = []
        self.selectedResultId = nil
    }
}

struct ResultCard: View {
    let result: PaletteResult
    let isSelected: Bool
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(result.color)
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                )
                .shadow(radius: isSelected ? 4 : 1)
            
            Text(result.name)
                .font(.caption2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(result.hex)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(), value: isSelected)
    }
}
