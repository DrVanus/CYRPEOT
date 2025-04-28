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
        // filtering and sorting logic
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
}
