import SwiftUI

struct GlobalMarketData: Codable {
    let totalMarketCap: [String: Double]
    let totalVolume: [String: Double]
    let marketCapPercentage: [String: Double]
    let marketCapChangePercentage24hUsd: Double?

    enum CodingKeys: String, CodingKey {
        case totalMarketCap = "total_market_cap"
        case totalVolume = "total_volume"
        case marketCapPercentage = "market_cap_percentage"
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
                Text("Total Market Cap: \(data.totalMarketCap[\"usd\"] ?? 0, specifier: \"%.2f\")")
                Text("Total Volume: \(data.totalVolume[\"usd\"] ?? 0, specifier: \"%.2f\")")
                Text("BTC Dominance: \(data.marketCapPercentage[\"btc\"] ?? 0, specifier: \"%.2f\")%")
                Text("24h Change: \(data.marketCapChangePercentage24hUsd ?? 0, specifier: \"%.2f\")%")
            } else {
                ProgressView()
                    .onAppear {
                        Task {
                            await marketVM.fetchGlobalMarketDataMulti()
                        }
                    }
            }
        }
        .padding()
    }
}
