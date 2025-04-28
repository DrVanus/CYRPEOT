//
//  HomeViewModel.swift
//  CRYPTOSAI
//
//  Minimal ViewModel to avoid duplication of coin structs.
//  Provides placeholders for watchlist, trending, and news.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var portfolioVM = PortfolioViewModel()
    @Published var newsVM      = CryptoNewsFeedViewModel()
    @Published var heatMapVM   = HeatMapViewModel()
    
    var heatMapTiles: [HeatMapTile] {
        heatMapVM.tiles
    }

    var heatMapWeights: [Double] {
        heatMapVM.weights()
    }
}
