//
//  CryptoSageAIApp.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI

@main
struct CryptoSageAIApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentManagerView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}