//
//  AppState.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var selectedTab: CustomTab = .home
    @Published var isDarkMode: Bool = true
}

enum CustomTab: String {
    case home      = "Home"
    case market    = "Market"
    case trade     = "Trade"
    case portfolio = "Portfolio"
    case ai        = "AI"
}
