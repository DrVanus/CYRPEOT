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
    
    // MARK: - Market Data Proxy
    @Published var marketVM = MarketViewModel()

    /// Expose trending coins for the Home screen
    var liveTrending: [MarketCoin] {
        marketVM.trendingCoins
    }

    /// Expose top gainers
    var liveTopGainers: [MarketCoin] {
        marketVM.topGainers
    }

    /// Expose top losers
    var liveTopLosers: [MarketCoin] {
        marketVM.topLosers
    }

    var heatMapTiles: [HeatMapTile] {
        heatMapVM.tiles
    }

    var heatMapWeights: [Double] {
        heatMapVM.weights()
    }
}
