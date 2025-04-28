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
}
