import Foundation
import Combine
import SwiftUI

@MainActor
class MarketViewModel: ObservableObject {
  // MARK: – Published Data
  @Published var coins: [MarketCoin] = []
  @Published var globalMarketCap: Double = 0
  @Published var volume24h: Double = 0
  @Published var btcDominance: Double = 0
  @Published var ethDominance: Double = 0
  @Published var globalData: GlobalMarketData? = nil

  // MARK: - View State & Filtering
  @Published var filteredCoins: [MarketCoin] = []
  @Published var searchText: String = ""
  @Published var showSearchBar: Bool = false
  @Published var selectedSegment: MarketSegment = .all
  @Published var sortField: SortField = .marketCap
  @Published var sortDirection: SortDirection = .desc

  private let favoritesKey = "favoriteCoinSymbols"
  private let pinnedCoins = ["BTC","ETH","BNB","XRP","ADA","DOGE","MATIC","SOL","DOT","LTC","SHIB","TRX","AVAX","LINK","UNI","BCH"]

  private var cancellables = Set<AnyCancellable>()
  private var coinRefreshTask: Task<Void, Never>?
  private var globalRefreshTask: Task<Void, Never>?

  init() {
    loadFavorites()                // mark saved favorites before fetch
    fetchMarketData()
    fetchGlobalMarketData()
    applyAllFiltersAndSort()       // prepare filtered list
    startAutoRefresh()
  }

  func fetchMarketData() {
      guard let url = URL(string:
          "https://api.coingecko.com/api/v3/coins/markets?" +
          "vs_currency=usd&order=market_cap_desc&per_page=20&page=1&sparkline=false&price_change_percentage=24h"
      ) else { return }

      URLSession.shared.dataTaskPublisher(for: url)
          .map(\.data)
          .decode(type: [MarketCoin].self, decoder: JSONDecoder())
          .receive(on: DispatchQueue.main)
          .sink { _ in
              // Ignore errors for now
          } receiveValue: { [weak self] coins in
              self?.coins = coins
              self?.loadFavorites()
              self?.applyAllFiltersAndSort()
          }
          .store(in: &cancellables)
  }

  func fetchGlobalMarketData() {
      guard let url = URL(string: "https://api.coingecko.com/api/v3/global") else { return }

      URLSession.shared.dataTaskPublisher(for: url)
          .map(\.data)
          .decode(type: GlobalMarketDataResponse.self, decoder: JSONDecoder())
          .receive(on: DispatchQueue.main)
          .sink { _ in
              // Ignore errors for now
          } receiveValue: { [weak self] response in
              let data = response.data
              self?.globalMarketCap = data.totalMarketCap["usd"] ?? 0
              self?.volume24h = data.totalVolume["usd"] ?? 0
              self?.btcDominance = data.marketCapPercentage["btc"] ?? 0
              self?.ethDominance = data.marketCapPercentage["eth"] ?? 0
          }
          .store(in: &cancellables)
  }

  /// Async variant for GlobalSummaryView
  func fetchGlobalMarketDataMulti() async {
      guard let url = URL(string: "https://api.coingecko.com/api/v3/global") else { return }
      do {
          let (rawData, _) = try await URLSession.shared.data(from: url)
          let response = try JSONDecoder().decode(GlobalMarketDataResponse.self, from: rawData)
          self.globalData = response.data
          let global = response.data
          self.globalMarketCap = global.totalMarketCap["usd"] ?? 0
          self.volume24h = global.totalVolume["usd"] ?? 0
          self.btcDominance = global.marketCapPercentage["btc"] ?? 0
          self.ethDominance = global.marketCapPercentage["eth"] ?? 0
      } catch {
          // Handle or log error
          print("Global data fetch error:", error)
      }
  }

  /// Async variant for MarketView
  func fetchMarketDataMulti() async {
      guard let url = URL(string:
          "https://api.coingecko.com/api/v3/coins/markets?" +
          "vs_currency=usd&order=market_cap_desc&per_page=20&page=1&sparkline=false&price_change_percentage=24h"
      ) else { return }
      do {
          let (data, _) = try await URLSession.shared.data(from: url)
          let newCoins = try JSONDecoder().decode([MarketCoin].self, from: data)
          await MainActor.run {
              self.coins = newCoins
              self.loadFavorites()
              self.applyAllFiltersAndSort()
          }
      } catch {
          print("Market data fetch error:", error)
      }
  }

  /// Starts background auto-refresh loops
  private func startAutoRefresh() {
      coinRefreshTask = Task.detached { [weak self] in
          guard let self = self else { return }
          while !Task.isCancelled {
              try? await Task.sleep(nanoseconds: 60_000_000_000) // 60s
              await self.fetchMarketDataMulti()
          }
      }
      globalRefreshTask = Task.detached { [weak self] in
          guard let self = self else { return }
          while !Task.isCancelled {
              try? await Task.sleep(nanoseconds: 180_000_000_000) // 180s
              await self.fetchGlobalMarketDataMulti()
          }
      }
  }

  // MARK: – Formatted Strings
  var globalMarketCapFormatted: String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.maximumFractionDigits = 0
    return f.string(from: .init(value: globalMarketCap)) ?? "$0"
  }

  var volume24hFormatted: String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.maximumFractionDigits = 0
    return f.string(from: .init(value: volume24h)) ?? "$0"
  }

  var btcDominanceFormatted: String { String(format: "%.1f%%", btcDominance) }
  var ethDominanceFormatted: String { String(format: "%.1f%%", ethDominance) }

  func loadFavorites() {
    let saved = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    for i in coins.indices {
      coins[i].isFavorite = saved.contains(coins[i].symbol.uppercased())
    }
  }

  func saveFavorites() {
    let faves = coins.filter { $0.isFavorite }.map { $0.symbol.uppercased() }
    UserDefaults.standard.setValue(faves, forKey: favoritesKey)
  }

  func toggleFavorite(_ coin: MarketCoin) {
    guard let idx = coins.firstIndex(where: { $0.id == coin.id }) else { return }
    withAnimation {
      coins[idx].isFavorite.toggle()
    }
    saveFavorites()
    applyAllFiltersAndSort()
  }

  func updateSearch(_ query: String) {
    searchText = query
    applyAllFiltersAndSort()
  }

  func updateSegment(_ seg: MarketSegment) {
    selectedSegment = seg
    applyAllFiltersAndSort()
  }

  func toggleSort(for field: SortField) {
    if sortField == field {
      sortDirection = (sortDirection == .asc ? .desc : .asc)
    } else {
      sortField = field
      sortDirection = .asc
    }
    applyAllFiltersAndSort()
  }

  func applyAllFiltersAndSort() {
    var result = coins
    let q = searchText.lowercased()
    if !q.isEmpty {
      result = result.filter {
        $0.name.lowercased().contains(q) ||
        $0.symbol.lowercased().contains(q)
      }
    }
    switch selectedSegment {
      case .all: break
      case .favorites: result = result.filter { $0.isFavorite }
      case .gainers: result = result.filter { $0.dailyChange > 0 }
      case .losers:  result = result.filter { $0.dailyChange < 0 }
    }
    filteredCoins = sortCoins(result)
  }

  private func sortCoins(_ arr: [MarketCoin]) -> [MarketCoin] {
    guard sortField != .none else { return arr }
    if searchText.isEmpty && selectedSegment == .all && sortField == .marketCap && sortDirection == .desc {
      let pinnedList = arr.filter { pinnedCoins.contains($0.symbol) }
      let others = arr.filter { !pinnedCoins.contains($0.symbol) }
      let sortedPinned = pinnedList.sorted {
        (pinnedCoins.firstIndex(of: $0.symbol) ?? 0) < (pinnedCoins.firstIndex(of: $1.symbol) ?? 0)
      }
      let sortedOthers = others.sorted { $0.marketCap > $1.marketCap }
      return sortedPinned + sortedOthers
    } else {
      return arr.sorted { a, b in
        switch sortField {
          case .coin:
            let c = a.symbol.localizedCaseInsensitiveCompare(b.symbol)
            return sortDirection == .asc ? (c == .orderedAscending) : (c == .orderedDescending)
          case .price:
            return sortDirection == .asc ? (a.price < b.price) : (a.price > b.price)
          case .dailyChange:
            return sortDirection == .asc ? (a.dailyChange < b.dailyChange) : (a.dailyChange > b.dailyChange)
          case .volume:
            return sortDirection == .asc ? (a.volume < b.volume) : (a.volume > b.volume)
          case .marketCap:
            return sortDirection == .asc ? (a.marketCap < b.marketCap) : (a.marketCap > b.marketCap)
          case .none:
            return false
        }
      }
    }
  }

  // MARK: - Computed Lists for HomeView
  var trendingCoins: [MarketCoin] {
    coins
      .filter { !pinnedCoins.contains($0.symbol) }
      .sorted { $0.volume > $1.volume }
  }

  var topGainers: [MarketCoin] {
    coins.sorted { $0.dailyChange > $1.dailyChange }
  }

  var topLosers: [MarketCoin] {
    coins.sorted { $0.dailyChange < $1.dailyChange }
  }

  // MARK: - Live Price Updates from Coinbase
  private let coinbaseService = CoinbaseService()

  func fetchLivePricesFromCoinbase() {
    Task { @MainActor in
      let favorites = coins.filter { $0.isFavorite }
      for coin in favorites {
        if let newPrice = try? await coinbaseService.fetchSpotPrice(coin: coin.symbol) {
          if let idx = coins.firstIndex(where: { $0.id == coin.id }) {
            coins[idx].price = newPrice
          }
        }
      }
      applyAllFiltersAndSort()
    }
  }
}

// MARK: - Global Market Data Response
struct GlobalMarketDataResponse: Codable {
    let data: GlobalMarketData
}

struct GlobalMarketData: Codable {
    let totalMarketCap: [String: Double]
    let totalVolume: [String: Double]
    let marketCapPercentage: [String: Double]

    enum CodingKeys: String, CodingKey {
        case totalMarketCap = "total_market_cap"
        case totalVolume = "total_volume"
        case marketCapPercentage = "market_cap_percentage"
    }
}
