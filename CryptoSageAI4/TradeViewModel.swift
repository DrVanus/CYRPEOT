//
//  TradeViewModel.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI
import Combine

class TradeViewModel: ObservableObject {
    @Published var selectedSymbol: String = "BTC-USD"
    @Published var side: String = "Buy"
    @Published var orderType: String = "Market"
    @Published var quantity: String = ""
    @Published var limitPrice: String = ""
    @Published var stopPrice: String = ""
    @Published var trailingStop: String = ""

    @Published var chartTimeframe: String = "60"
    @Published var aiSuggestion: String = ""
    @Published var userBalance: Double = 5000.0

    func submitOrder() {
        aiSuggestion = "AI Suggestion: For \(selectedSymbol), consider a trailing stop at \(trailingStop)."
    }

    func applyFraction(_ fraction: Double) {
        // Hard-coded fallback
        let price = (Double(limitPrice) ?? 0) > 0 ? Double(limitPrice)! : 20000.0
        let amountToSpend = userBalance * fraction
        let coinQty = amountToSpend / price
        quantity = String(format: "%.4f", coinQty)
    }
}