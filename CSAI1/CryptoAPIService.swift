import Foundation

enum CryptoAPIError: Error {
    case invalidURL
    case requestFailed
    case decodingError
}

class CryptoAPIService {
    static let shared = CryptoAPIService()
    private init() {}
    
    /// Fetches the current USD prices for a list of coin IDs.
    func getCurrentPrices(for coinIDs: [String]) async throws -> [String: Double] {
        let ids = coinIDs.joined(separator: ",")
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=\(ids)&vs_currencies=usd") else {
            throw CryptoAPIError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CryptoAPIError.decodingError
        }
        var prices: [String: Double] = [:]
        for (coin, value) in json {
            if let dict = value as? [String: Double], let usdPrice = dict["usd"] {
                prices[coin] = usdPrice
            }
        }
        return prices
    }

    /// Fetches historical price data for a specific coin over the past given number of days.
    func getHistoricalPrices(for coinID: String, days: Int) async throws -> [(Date, Double)] {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(coinID)/market_chart?vs_currency=usd&days=\(days)") else {
            throw CryptoAPIError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pricesArray = json["prices"] as? [[Any]] else {
            throw CryptoAPIError.decodingError
        }
        var historicalPrices: [(Date, Double)] = []
        for entry in pricesArray {
            if let timestamp = entry[0] as? Double,
               let price = entry[1] as? Double {
                let date = Date(timeIntervalSince1970: timestamp / 1000)
                historicalPrices.append((date, price))
            }
        }
        return historicalPrices
    }

    // MARK: - CoinGecko Global Data

    /// Fetches global market data from CoinGecko.
    func fetchGlobalData() async throws -> GlobalMarketData {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/global") else {
            throw CryptoAPIError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        struct Wrapper: Decodable {
            let data: GlobalMarketData
        }
        let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
        return wrapper.data
    }

    /// Fallback: Fetches global market data from CoinPaprika.
    func fetchGlobalDataFromPaprika() async throws -> GlobalMarketData {
        guard let url = URL(string: "https://api.coinpaprika.com/v1/global") else {
            throw CryptoAPIError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        struct PaprikaGlobal: Decodable {
            let market_cap_usd: Double
            let volume_24h_usd: Double
            let bitcoin_dominance_percentage: Double
        }
        let pg = try JSONDecoder().decode(PaprikaGlobal.self, from: data)
        return GlobalMarketData(
            totalMarketCap: ["usd": pg.market_cap_usd],
            totalVolume: ["usd": pg.volume_24h_usd],
            marketCapPercentage: ["btc": pg.bitcoin_dominance_percentage, "eth": 0],
            marketCapChangePercentage24hUsd: 0
        )
    }

    // MARK: - CoinGecko Market Coins

    enum CoinGeckoOrder: String {
        case marketCapDesc = "market_cap_desc"
    }

    /// Fetches market coin data from CoinGecko with the given parameters.
    func fetchCoinGeckoMarkets(
        vsCurrency: String,
        order: CoinGeckoOrder,
        perPage: Int,
        page: Int,
        sparkline: Bool
    ) async throws -> [MarketCoin] {
        var comps = URLComponents(string: "https://api.coingecko.com/api/v3/coins/markets")!
        comps.queryItems = [
            URLQueryItem(name: "vs_currency", value: vsCurrency),
            URLQueryItem(name: "order", value: order.rawValue),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sparkline", value: sparkline ? "true" : "false"),
            URLQueryItem(name: "price_change_percentage", value: "1h,24h")
        ]
        guard let url = comps.url else {
            throw CryptoAPIError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([MarketCoin].self, from: data)
    }

    // MARK: - CoinPaprika Market Coins Fallback

    /// Fetches market coin data from CoinPaprika as a fallback.
    func fetchCoinPaprikaMarkets(limit: Int, offset: Int) async throws -> [MarketCoin] {
        guard let url = URL(string: "https://api.coinpaprika.com/v1/tickers?limit=\(limit)&offset=\(offset)") else {
            throw CryptoAPIError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        struct PaprikaTicker: Decodable {
            let id: String
            let name: String
            let symbol: String
            let quotes: [String: PaprikaQuote]
        }
        struct PaprikaQuote: Decodable {
            let price: Double
            let volume_24h: Double
            let market_cap: Double
            let percent_change_24h: Double
            let percent_change_1h: Double?
        }
        let tickers = try JSONDecoder().decode([PaprikaTicker].self, from: data)
        return tickers.map { t in
            let q = t.quotes["USD"]!
            return MarketCoin(
                id: UUID(),                        // generate a new UUID
                symbol: t.symbol,
                name: t.name,
                price: q.price,
                dailyChange: q.percent_change_24h,
                hourlyChange: q.percent_change_1h ?? 0,
                volume: q.volume_24h,
                marketCap: q.market_cap,
                isFavorite: false,
                sparklineData: nil,
                imageUrl: nil,
                finalImageUrl: nil
            )
        }
    }
}
