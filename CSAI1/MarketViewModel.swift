import SwiftUI
import Combine
import Foundation

@MainActor
class MarketViewModel: ObservableObject {
    private let favoritesKey = "favoriteCoinSymbols"
    // MARK: - Published Data
    @Published var coins: [MarketCoin] = []
    @Published var globalMarketCap: Double = 0
    @Published var volume24h: Double = 0
    @Published var btcDominance: Double = 0
    @Published var ethDominance: Double = 0
    @Published var globalData: GlobalMarketData? = nil
    @Published var isMarketLoading: Bool = false
    @Published var isGlobalLoading: Bool = false

    // MARK: - Error & Cache State
    @Published var coinError: String?
    @Published var globalError: String?

    // MARK: - View State & Filtering
    @Published var filteredCoins: [MarketCoin] = []
    @Published var searchText: String = ""
    @Published var showSearchBar: Bool = false
    @Published var selectedSegment: MarketSegment = .all
    @Published var sortField: SortField = .marketCap
    @Published var sortDirection: SortDirection = .desc

    private var cancellables = Set<AnyCancellable>()
    private var coinRefreshTask: Task<Void, Never>?
    private var globalRefreshTask: Task<Void, Never>?

    /// Task handle for coalescing market-data fetches
    private var marketRefreshTask: Task<Void, Never>?

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.timeoutIntervalForRequest = 15
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()

    init() {
        // 1. Load cached coins if available
        if let cachedCoins = MarketCacheManager.shared.loadCoinsFromDisk() {
            self.coins = cachedCoins
            applyFilterAndSort()
        }
        // 2. Load cached global data if available
        if let cachedGlobal = GlobalCacheManager.shared.loadGlobalDataFromDisk() {
            self.globalData = cachedGlobal
        }
        // Kick off coalesced market-data fetch on init
        fetchMarketDataMulti()
    }

    func fetchGlobalData() {
        globalRefreshTask?.cancel()
        isGlobalLoading = true
        globalRefreshTask = Task { [weak self] in
            guard let self = self else { return }
            defer { Task { @MainActor in self.isGlobalLoading = false } }
            // Primary fetch
            do {
                let data = try await CryptoAPIService.shared.fetchGlobalData()
                await MainActor.run {
                    self.globalData = data
                    self.globalMarketCap = data.totalMarketCap["usd"] ?? 0
                    self.volume24h     = data.totalVolume["usd"] ?? 0
                    self.btcDominance  = data.marketCapPercentage["btc"] ?? 0
                    self.ethDominance  = data.marketCapPercentage["eth"] ?? 0
                    self.globalError   = nil
                    GlobalCacheManager.shared.saveGlobalDataToDisk(data)
                }
            } catch {
                // Fallback
                do {
                    let fallback = try await CryptoAPIService.shared.fetchGlobalDataFromPaprika()
                    await MainActor.run {
                        self.globalData      = fallback
                        self.globalMarketCap = fallback.totalMarketCap["usd"] ?? 0
                        self.volume24h       = fallback.totalVolume["usd"] ?? 0
                        self.btcDominance    = fallback.marketCapPercentage["btc"] ?? 0
                        self.ethDominance    = fallback.marketCapPercentage["eth"] ?? 0
                        self.globalError     = nil
                    }
                } catch {
                    await MainActor.run { self.globalError = "Could not load global data." }
                }
            }
        }
    }

    private func applyFilterAndSort() {
        var updatedCoins = coins

        // 1. Filter by search text
        if !searchText.isEmpty {
            let lowercasedQuery = searchText.lowercased()
            updatedCoins = updatedCoins.filter {
                $0.name.lowercased().contains(lowercasedQuery) ||
                $0.symbol.lowercased().contains(lowercasedQuery)
            }
        }

        // 2. Filter by segment
        switch selectedSegment {
        case .all:
            break
        case .favorites:
            updatedCoins = updatedCoins.filter { $0.isFavorite }
        case .gainers:
            updatedCoins = updatedCoins.filter { $0.dailyChange > 0 }
        case .losers:
            updatedCoins = updatedCoins.filter { $0.dailyChange < 0 }
        }

        // 3. Sort based on selected field and direction
        switch sortField {
        case .coin:
            updatedCoins = updatedCoins.sorted {
                sortDirection == .asc
                  ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                  : $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending
            }
        case .marketCap:
            updatedCoins = updatedCoins.sorted {
                sortDirection == .asc ? $0.marketCap < $1.marketCap : $0.marketCap > $1.marketCap
            }
        case .price:
            updatedCoins = updatedCoins.sorted {
                sortDirection == .asc ? $0.price < $1.price : $0.price > $1.price
            }
        case .dailyChange:
            updatedCoins = updatedCoins.sorted {
                sortDirection == .asc ? $0.dailyChange < $1.dailyChange : $0.dailyChange > $1.dailyChange
            }
        case .volume:
            updatedCoins = updatedCoins.sorted {
                sortDirection == .asc ? $0.volume < $1.volume : $0.volume > $1.volume
            }
        }

        // 4. Publish filtered & sorted list on main thread
        DispatchQueue.main.async {
            self.filteredCoins = updatedCoins
        }
    }

    /// Public alias for SwiftUI views to apply filtering and sorting
    func applyAllFiltersAndSort() {
        applyFilterAndSort()
    }

    

    /// Update the selected segment and reapply filters
    func updateSegment(_ seg: MarketSegment) {
        selectedSegment = seg
        applyAllFiltersAndSort()
    }

    /// Toggle the sort field and direction, then reapply filters.
    func toggleSort(for field: SortField) {
        // If tapping the same field, reverse the direction; otherwise, set the new field
        if sortField == field {
            sortDirection = (sortDirection == .asc ? .desc : .asc)
        } else {
            sortField = field
        }
        // Reapply filtering and sorting
        applyAllFiltersAndSort()
    }
    // MARK: - Live Price Updates
    /// Refreshes only watchlist coins’ prices by calling your Coinbase service
    func fetchLivePricesFromCoinbase() {
        Task { @MainActor in
            do {
                // Replace with your actual Coinbase fetch logic:
                // let updatedCoins = try await CoinbaseService.shared.fetchPrices(for: self.coins)
                // self.coins = updatedCoins
                print("fetchLivePricesFromCoinbase() called")
                applyFilterAndSort()
            } catch {
                print("Error fetching live prices from Coinbase: \(error)")
            }
        }
    }

    /// Toggle favorite status on a coin
    func toggleFavorite(_ coin: MarketCoin) {
        guard let index = coins.firstIndex(where: { $0.id == coin.id }) else { return }
        coins[index].isFavorite.toggle()
        saveFavorites()                     // NEW: persist favorites
        Task { @MainActor in
            withAnimation {
                applyFilterAndSort()        // NEW: immediately update the filtered list
            }
        }
    }
    
    /// Internal async market-data fetch logic (no task cancellation)
    private func performFetchMarketDataMulti() async {
        // -- Global Data --
        DispatchQueue.main.async {
            self.globalError = nil
            self.isGlobalLoading = true
        }
        do {
            let data = try await CryptoAPIService.shared.fetchGlobalData()
            DispatchQueue.main.async {
                self.globalData      = data
                self.globalMarketCap = data.totalMarketCap["usd"] ?? 0
                self.volume24h       = data.totalVolume["usd"] ?? 0
                self.btcDominance    = data.marketCapPercentage["btc"] ?? 0
                self.ethDominance    = data.marketCapPercentage["eth"] ?? 0
                GlobalCacheManager.shared.saveGlobalDataToDisk(data)
                self.isGlobalLoading = false
            }
        } catch {
            // Fallback to Paprika
            do {
                let fallback = try await CryptoAPIService.shared.fetchGlobalDataFromPaprika()
                DispatchQueue.main.async {
                    self.globalData      = fallback
                    self.globalMarketCap = fallback.totalMarketCap["usd"] ?? 0
                    self.volume24h       = fallback.totalVolume["usd"] ?? 0
                    self.btcDominance    = fallback.marketCapPercentage["btc"] ?? 0
                    self.ethDominance    = fallback.marketCapPercentage["eth"] ?? 0
                    self.isGlobalLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.globalError = "Could not load global data."
                    self.isGlobalLoading = false
                }
            }
        }

        // -- Market Coins --
        DispatchQueue.main.async {
            self.coinError = nil
            self.isMarketLoading = true
        }
        do {
            let geckoCoins = try await CryptoAPIService.shared.fetchCoinGeckoMarkets(
                vsCurrency: "usd",
                order: .marketCapDesc,
                perPage: 20,
                page: 1,
                sparkline: false
            )
            DispatchQueue.main.async {
                self.coins = geckoCoins
                MarketCacheManager.shared.saveCoinsToDisk(geckoCoins)
                self.loadFavorites()
                self.applyFilterAndSort()
            }
        } catch {
            // Fallback to Paprika
            do {
                let paprikaCoins = try await CryptoAPIService.shared.fetchCoinPaprikaMarkets(
                    limit: 20,
                    offset: 0
                )
                DispatchQueue.main.async {
                    self.coins = paprikaCoins
                    self.loadFavorites()
                    self.applyFilterAndSort()
                }
            } catch {
                DispatchQueue.main.async {
                    self.coinError = "Could not load market data."
                }
            }
        }
        // -- Finalize --
        DispatchQueue.main.async {
            self.loadFavorites()
            self.applyFilterAndSort()
            self.isMarketLoading = false
        }
    }

    /// Public market-data fetch that cancels any in-flight fetch before starting a new one
    func fetchMarketDataMulti() {
        // Cancel any ongoing market fetch
        marketRefreshTask?.cancel()
        marketRefreshTask = Task { [weak self] in
            guard let self = self else { return }
            await self.performFetchMarketDataMulti()
        }
    }

    // MARK: - Computed Properties for UI

    /// Formatted global market cap (USD)
    var globalMarketCapFormatted: String {
        let cap = globalData?.totalMarketCap["usd"] ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: cap)) ?? "$0"
    }

    /// Formatted 24h volume (USD)
    var volume24hFormatted: String {
        let vol = globalData?.totalVolume["usd"] ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: vol)) ?? "$0"
    }

    /// BTC market dominance percentage
    var btcDominanceFormatted: String {
        let dom = globalData?.marketCapPercentage["btc"] ?? 0
        return String(format: "%.2f%%", dom)
    }

    /// ETH market dominance percentage
    var ethDominanceFormatted: String {
        let dom = globalData?.marketCapPercentage["eth"] ?? 0
        return String(format: "%.2f%%", dom)
    }

    // MARK: - Coin Lists for UI

    /// A small sample of trending coins (first 10 by default order)
    var trendingCoins: [MarketCoin] {
        Array(coins.prefix(10))
    }

    /// Top gainers over 24h
    var topGainers: [MarketCoin] {
        Array(coins.sorted { $0.dailyChange > $1.dailyChange }.prefix(10))
    }

    /// Top losers over 24h
    var topLosers: [MarketCoin] {
        Array(coins.sorted { $0.dailyChange < $1.dailyChange }.prefix(10))
    }

    private func saveFavorites() {
        let symbols = coins.filter { $0.isFavorite }.map { $0.symbol }
        UserDefaults.standard.setValue(symbols, forKey: favoritesKey)
    }

    private func loadFavorites() {
        guard let saved = UserDefaults.standard.stringArray(forKey: favoritesKey) else { return }
        for i in coins.indices {
            coins[i].isFavorite = saved.contains(coins[i].symbol)
        }
        DispatchQueue.main.async {
            self.applyFilterAndSort()
        }
    }
}
