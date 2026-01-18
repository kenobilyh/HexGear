//
//  AppState.swift
//  HexGear
//
//  Created by Jeff Lin on 2026/1/17.
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    // Keys
    private let historyKey = "colorHistory"
    private let codeFormatKey = "codeFormat"
    
    // Published properties
    @Published var history: [Color] = [] {
        didSet {
            saveHistory()
        }
    }
    
    @Published var codeFormat: CodeFormat = .swiftUI {
        didSet {
            UserDefaults.standard.set(codeFormat.rawValue, forKey: codeFormatKey)
        }
    }
    
    init() {
        // For debug: reset UserDefaults
//        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        // Load CodeFormat
        if let savedFormat = UserDefaults.standard.string(forKey: codeFormatKey),
           let format = CodeFormat(rawValue: savedFormat) {
            self.codeFormat = format
        }
        
        // Load History
        loadHistory()
    }
    
    private func loadHistory() {
        if let savedHexCodes = UserDefaults.standard.stringArray(forKey: historyKey) {
            self.history = savedHexCodes.compactMap { Color(hex: $0) }
        }
    }
    
    private func saveHistory() {
        let hexCodes = history.compactMap { $0.toHex(includeAlpha: true) }
        UserDefaults.standard.set(hexCodes, forKey: historyKey)
    }
}
