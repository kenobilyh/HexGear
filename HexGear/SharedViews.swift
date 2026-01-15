//
//  SharedViews.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/11.
//

import SwiftUI

// MARK: - 5. 共用組件 (Shared Components)

struct RGBField: View {
    let label: String
    @Binding var value: Int
    @State private var textInput: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).bold().foregroundColor(.secondary)
            TextField("", text: $textInput)
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
                .focused($isFocused)
                // update textInput when external value changes (only if not focused to avoid fighting)
                .onChange(of: value) { _, newValue in
                    if !isFocused {
                        textInput = "\(newValue)"
                    }
                }
                // initial set
                .onAppear {
                    textInput = "\(value)"
                }
                // Update value when text changes
                .onChange(of: textInput) { _, newValue in
                    // Allow empty for editing experience
                    if newValue.isEmpty { return }
                    
                    // Filter non-numbers
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    
                    if filtered != newValue {
                         textInput = filtered
                    }
                    
                    if let intVal = Int(filtered) {
                        // Clamp to 0-255
                        if intVal > 255 {
                            textInput = "255"
                            value = 255
                        } else {
                            value = intVal
                        }
                    }
                }
                // When focus is lost, ensure valid state
                .onSubmit {
                    validateInput()
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        validateInput()
                    }
                }
        }
    }
    
    private func validateInput() {
        if let intVal = Int(textInput) {
            value = min(max(intVal, 0), 255)
            textInput = "\(value)"
        } else {
            // reset to current valid value if input is invalid/empty
            textInput = "\(value)"
        }
    }
}

struct StatusBadge: View {
    let pass: Bool
    let label: String
    
    var body: some View {
        HStack {
            Image(systemName: pass ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            Text(label).font(.caption)
            Spacer()
            // using NSLocalizedString here as it is inside a ternary operator
            Text(pass ? NSLocalizedString("pass", comment: "") : NSLocalizedString("fail", comment: "")).font(.caption2.monospaced())
        }
        .padding(6)
        .background(pass ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
        .foregroundColor(pass ? .green : .red)
        .cornerRadius(6)
    }
}

struct CodeOutputView: View {
    @Binding var format: CodeFormat
    let color: Color
    @State private var justCopied = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("\(NSLocalizedString("output_format", comment: "")): \(format.rawValue)", systemImage: "terminal").font(.caption.bold())
                Spacer()
                Menu {
                    ForEach(CodeFormat.allCases) { fmt in
                        Button(fmt.label) { format = fmt }
                    }
                } label: {
                    Text(LocalizedStringKey("change"))
                }
                .menuStyle(.borderlessButton)
            }
            
            let code = generateCode(format: format, color: color)
            
            HStack {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.green)
                    .lineLimit(1)
                
                Spacer()
                
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    withAnimation {
                        justCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        justCopied = false
                    }
                } label: {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
        }
    }
}

struct HexInputView: View {
    @Binding var hexInput: String
    @Binding var selectedColor: Color
    
    var body: some View {
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
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(hexInput, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
            }
            .padding(6)
        } label: {
            Text(LocalizedStringKey("hex_code")).font(.caption).foregroundColor(.secondary)
        }
    }
}
