//
//  CoinGeckoCoin 2.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI

// MARK: - CoinGeckoCoin
struct CoinGeckoCoin: Decodable, Identifiable {
    var id = UUID()
    let coinGeckoID: String
    let symbol: String
    let name: String?
    let currentPrice: Double?
    let priceChangePercentage24h: Double?
    let high24h: Double?
    let low24h: Double?
    let totalVolume: Double?
    let marketCap: Double?
    let circulatingSupply: Double?

    enum CodingKeys: String, CodingKey {
        case coinGeckoID = "id"
        case symbol
        case name
        case currentPrice = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case high24h = "high_24h"
        case low24h  = "low_24h"
        case totalVolume = "total_volume"
        case marketCap   = "market_cap"
        case circulatingSupply = "circulating_supply"
    }
}

// MARK: - Trending
struct TrendingResponse: Decodable {
    let coins: [TrendingCoinWrapper]
    struct TrendingCoinWrapper: Decodable {
        let item: TrendingItem
    }
}

struct TrendingItem: Decodable {
    let id: String
    let symbol: String
    let priceBtc: Double

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case priceBtc = "price_btc"
    }
}

struct TrendingCoin: Identifiable {
    let id: String
    let symbol: String
    let price: Double
    let priceChange24h: Double

    var uniqueID = UUID()
    var identity: UUID { uniqueID }
}

// MARK: - News
struct CryptoCompareNewsResponse: Decodable {
    let Data: [CryptoCompareNewsItem]
}

struct CryptoCompareNewsItem: Decodable {
    let title: String
    let source: String
    let url: String
}

struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let source: String
    let url: URL?
}

// MARK: - Market Item
struct MarketItem: Identifiable {
    let id = UUID()
    let symbol: String
    let price: Double
    let change: Double
}

// MARK: - Holdings & Portfolio
struct Holding: Identifiable, Codable {
    let id = UUID()
    var symbol: String
    var amount: Double
    var totalValue: Double
    var dailyChangePercent: Double
}

// MARK: - Segments for ring chart
struct Segment {
    let color: Color
    let fraction: Double
    let label: String
}

// MARK: - ChatMessage
enum MessageRole {
    case user, assistant, system
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String

    var roleString: String {
        switch role {
        case .assistant: return "assistant"
        case .system:    return "system"
        case .user:      return "user"
        }
    }
}