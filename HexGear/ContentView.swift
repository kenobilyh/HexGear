//
//  ContentView.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/11.
//

import SwiftUI

// MARK: - 2. 主視圖 (Main Views)

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @AppStorage("codeFormat") private var codeFormat: CodeFormat = .swiftUI
    
    // 共享狀態
    @State private var history: [Color] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ConverterView(history: $history, codeFormat: $codeFormat)
                .tabItem {
                    Label(LocalizedStringKey("tab_converter"), systemImage: "arrow.left.arrow.right")
                }
                .tag(0)
            
            BlenderView(codeFormat: $codeFormat)
                .tabItem {
                    Label(LocalizedStringKey("tab_blender"), systemImage: "drop.fill")
                }
                .tag(1)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 600)
    }
}

// 預覽
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
