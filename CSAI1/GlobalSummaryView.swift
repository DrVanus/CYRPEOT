import SwiftUI

// 1. Define your data model with real properties:
struct GlobalMarketData: Codable {
    let totalMarketCap: [String: Double]
    let totalVolume:   [String: Double]
    let marketCapPercentage: [String: Double]
    let marketCapChangePercentage24hUsd: Double

    enum CodingKeys: String, CodingKey {
        case totalMarketCap               = "total_market_cap"
        case totalVolume                  = "total_volume"
        case marketCapPercentage          = "market_cap_percentage"
        case marketCapChangePercentage24hUsd = "market_cap_change_percentage_24h_usd"
    }
}

struct GlobalSummaryView: View {
    @EnvironmentObject var marketVM: MarketViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Global Market Summary")
                .font(.largeTitle)
                .padding(.bottom, 4)

            if let data = marketVM.globalData {
                // 2. Pull out the raw Doubles:
                let cap       = data.totalMarketCap["usd"] ?? 0
                let volume    = data.totalVolume["usd"] ?? 0
                let dominance = data.marketCapPercentage["btc"] ?? 0
                let change    = data.marketCapChangePercentage24hUsd

                // 3. Format them cleanly:
                Text("Total Market Cap: \(String(format: "%.2f", cap))")
                Text("Total Volume:    \(String(format: "%.2f", volume))")
                Text("BTC Dominance:   \(String(format: "%.2f", dominance))%")
                Text("24h Change:      \(String(format: "%.2f", change))%")
            } else {
                ProgressView()
                    .task {
                        // Use the async method defined in your view model
                        await marketVM.fetchMarketDataMulti()
                    }
            }
        }
        .padding()
    }
}
