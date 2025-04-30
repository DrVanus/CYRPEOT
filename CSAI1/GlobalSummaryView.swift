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

            // Loading, Error, or Data display
            if marketVM.isGlobalLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else if let error = marketVM.globalError {
                DataUnavailableView(message: error) {
                    Task { await marketVM.fetchGlobalData() }
                }
                .padding(.vertical, 8)
            } else if let data = marketVM.globalData {
                // Data available – formatted display
                let cap       = data.totalMarketCap["usd"] ?? 0
                let volume    = data.totalVolume["usd"] ?? 0
                let dominance = data.marketCapPercentage["btc"] ?? 0
                let change    = data.marketCapChangePercentage24hUsd

                Text("Total Market Cap: \(cap.formatted(.currency(code: "USD")))")
                Text("Total Volume:    \(volume.formatted(.currency(code: "USD")))")
                Text("BTC Dominance:   \(String(format: "%.2f", dominance))%")
                Text("24h Change:      \(String(format: "%.2f", change))%")
            } else {
                Text("Global data unavailable")
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }
        }
        .padding()
    }
}
