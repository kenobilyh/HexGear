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
    let value: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).bold().foregroundColor(.secondary)
            Text("\(value)")
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
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
