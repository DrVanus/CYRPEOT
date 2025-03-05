//
//  MarketViewModel.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//

import SwiftUI
import Combine

class MarketViewModel: ObservableObject {
    @Published var marketCoins: [CoinGeckoCoin] = []
    @Published var isLoading = false

    func fetchMarketCoins() {
        isLoading = true
        guard let url = URL(string:
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=200&page=1&sparkline=false"
        ) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                print("Error fetching market coins: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([CoinGeckoCoin].self, from: data)
                DispatchQueue.main.async {
                    self.marketCoins = decoded
                }
            } catch {
                print("Error decoding market coins: \(error)")
            }
        }.resume()
    }
}
