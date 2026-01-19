//
//  HexGearApp.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/11.
//

import SwiftUI

@main
struct HexGearApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        
        MenuBarExtra("Color Tool", image: "MenuBarIcon") {
            ConverterView(history: $appState.history, codeFormat: $appState.codeFormat)
            
            Divider()
            
            Button("Open Main Window") {
                // 開啟主視窗的邏輯
                NSApp.activate(ignoringOtherApps: true)
                // 實作上通常會配合 URL Scheme 或 WindowController
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window) // 使用視窗樣式，支援複雜 UI
    }
}
