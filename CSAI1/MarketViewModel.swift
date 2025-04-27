import Foundation
import Combine

@MainActor
class MarketViewModel: ObservableObject {
  // MARK: – Published Data
  @Published var coins: [MarketCoin] = []
  @Published var globalMarketCap: Double = 0
  @Published var volume24h: Double = 0
  @Published var btcDominance: Double = 0
  @Published var ethDominance: Double = 0

  // MARK: - Raw Global Data
  @Published var globalData: GlobalMarketData?

  private var cancellables = Set<AnyCancellable>()

  init() {
    fetchMarketData()
    fetchGlobalMarketData()
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
          let (data, _) = try await URLSession.shared.data(from: url)
          let response = try JSONDecoder().decode(GlobalMarketDataResponse.self, from: data)
          await MainActor.run {
              self.globalData = response.data
          }
      } catch {
          // Handle or log error
          print("Global data fetch error:", error)
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
