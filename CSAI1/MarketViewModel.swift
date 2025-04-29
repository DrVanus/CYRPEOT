import SwiftUI
import Combine
import Foundation

@MainActor
class MarketViewModel: ObservableObject {
    // MARK: - Published Data
    @Published var coins: [MarketCoin] = []
    @Published var globalMarketCap: Double = 0
    @Published var volume24h: Double = 0
    @Published var btcDominance: Double = 0
    @Published var ethDominance: Double = 0
    @Published var globalData: GlobalMarketData? = nil
    @Published var isMarketLoading: Bool = false
    @Published var isGlobalLoading: Bool = false

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

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = 15
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()

    init() {
        fetchGlobalData()
        refreshCoins()
    }

    func fetchGlobalData() {
        isGlobalLoading = true
        globalRefreshTask?.cancel()
        globalRefreshTask = Task {
            defer { isGlobalLoading = false }
            do {
                let url = URL(string: "https://api.coingecko.com/api/v3/global")!
                let (data, _) = try await session.data(from: url)
                let response = try JSONDecoder().decode(GlobalMarketDataResponse.self, from: data)
                self.globalData = response.data
            } catch {
                print("Global data fetch error: \(error)")
            }
        }
    }

    func refreshCoins() {
        isMarketLoading = true
        coinRefreshTask?.cancel()
        coinRefreshTask = Task {
            defer { isMarketLoading = false }
            do {
                var urlComponents = URLComponents(string: "https://api.coingecko.com/api/v3/coins/markets")!
                urlComponents.queryItems = [
                    URLQueryItem(name: "vs_currency", value: "usd"),
                    URLQueryItem(name: "order", value: "market_cap_desc"),
                    URLQueryItem(name: "per_page", value: "20"),
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "sparkline", value: "false"),
                    URLQueryItem(name: "price_change_percentage", value: "24h")
                ]
                let (data, _) = try await session.data(from: urlComponents.url!)
                let decodedCoins = try JSONDecoder().decode([MarketCoin].self, from: data)
                self.coins = decodedCoins
                applyFilterAndSort()
            } catch {
                print("Market data fetch error: \(error)")
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
        case .marketCap:
            updatedCoins = updatedCoins.sorted {
                sortDirection == .asc ? $0.marketCap < $1.marketCap : $0.marketCap > $1.marketCap
            }
        case .price:
            updatedCoins = updatedCoins.sorted(by: { (a: MarketCoin, b: MarketCoin) -> Bool in
                sortDirection == .asc ? a.currentPrice < b.currentPrice : a.currentPrice > b.currentPrice
            })
        case .priceChangePercentage24h:
            updatedCoins = updatedCoins.sorted(by: { (a: MarketCoin, b: MarketCoin) -> Bool in
                sortDirection == .asc ? a.dailyChange < b.dailyChange : a.dailyChange > b.dailyChange
            })
        default:
            break
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

    /// Async alias so views can exclusively fetch only global market data
    func fetchGlobalMarketDataMulti() async {
        fetchGlobalData()
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
        // If you need to persist favorites, do that here.
    }
    
    /// Fetch both global summary and market coins
    func fetchMarketDataMulti() async {
        // Kick off global data refresh
        fetchGlobalData()
        // Refresh full coin list
        refreshCoins()
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
}
