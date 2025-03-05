//
//  HomeViewModel.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var showSettings: Bool = false

    @Published var trendingCoins: [TrendingCoin] = []
    @Published var watchlistCoins: [CoinGeckoCoin] = []
    @Published var news: [NewsItem] = []

    @Published var isLoadingCoins: Bool = false
    @Published var isLoadingNews: Bool = false

    // user-starred coin IDs
    @Published var watchlistIDs: Set<String> = ["bitcoin", "ethereum", "solana"]
    
    // WALLET SUPPORT
    @Published var userWallets: [UserWallet] = []
    
    func loadUserWallets() {
        guard let data = UserDefaults.standard.data(forKey: "userWalletsData") else { return }
        do {
            let decoded = try JSONDecoder().decode([UserWallet].self, from: data)
            self.userWallets = decoded
        } catch {
            print("Error decoding userWallets: \(error)")
        }
    }

    func saveUserWallets() {
        do {
            let data = try JSONEncoder().encode(userWallets)
            UserDefaults.standard.set(data, forKey: "userWalletsData")
        } catch {
            print("Error encoding userWallets: \(error)")
        }
    }

    func refreshWatchlistData() {
        let joinedIDs = watchlistIDs.joined(separator: ",")
        if joinedIDs.isEmpty {
            DispatchQueue.main.async {
                self.watchlistCoins = []
            }
            return
        }
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=\(joinedIDs)&order=market_cap_desc&per_page=100&page=1&sparkline=false"
        guard let url = URL(string: urlString) else { return }

        self.isLoadingCoins = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingCoins = false
            }
            if let error = error {
                print("Error fetching watchlist data: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([CoinGeckoCoin].self, from: data)
                DispatchQueue.main.async {
                    self.watchlistCoins = decoded
                }
            } catch {
                print("Error decoding watchlist data: \(error)")
            }
        }.resume()
    }

    func fetchNews() {
        isLoadingNews = true
        guard let url = URL(string: "https://min-api.cryptocompare.com/data/v2/news/?lang=EN") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingNews = false
            }
            if let error = error {
                print("Error fetching news: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(CryptoCompareNewsResponse.self, from: data)
                let mapped = decoded.Data.prefix(5).map { item -> NewsItem in
                    let possibleURL = URL(string: item.url)
                    return NewsItem(
                        title: item.title,
                        source: item.source,
                        url: possibleURL
                    )
                }
                DispatchQueue.main.async {
                    self.news = Array(mapped)
                }
            } catch {
                print("Error decoding news: \(error)")
            }
        }.resume()
    }

    func fetchTrending() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/search/trending") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching trending: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(TrendingResponse.self, from: data)
                let mapped = decoded.coins.map { coin -> TrendingCoin in
                    let rawPrice = coin.item.priceBtc
                    let finalPrice = (rawPrice > 0) ? (rawPrice * 27000) : 0.0
                    return TrendingCoin(
                        id: coin.item.id,
                        symbol: coin.item.symbol,
                        price: finalPrice,
                        priceChange24h: Double.random(in: -10...10)
                    )
                }
                DispatchQueue.main.async {
                    self.trendingCoins = mapped
                }
            } catch {
                print("Error decoding trending: \(error)")
            }
        }.resume()
    }

    func fetchCoinByID(_ coinID: String, completion: @escaping (CoinGeckoCoin?) -> Void) {
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=\(coinID)&order=market_cap_desc&per_page=1&page=1&sparkline=false"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("fetchCoinByID error: \(error)")
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            do {
                let result = try JSONDecoder().decode([CoinGeckoCoin].self, from: data)
                completion(result.first)
            } catch {
                print("Error decoding single coin: \(error)")
                completion(nil)
            }
        }.resume()
    }

    func addToWatchlist(coinID: String) {
        watchlistIDs.insert(coinID)
    }

    func removeFromWatchlist(coinID: String) {
        watchlistIDs.remove(coinID)
    }
}