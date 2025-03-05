//
//  CoinDetailView.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI

struct CoinDetailView: View {
    let coin: CoinGeckoCoin
    @ObservedObject var homeVM: HomeViewModel
    var tradeVM: TradeViewModel? = nil

    @EnvironmentObject var appState: AppState
    @State private var timeframe: TradeTimeframe = .oneHour

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                ScrollView {
                    VStack(spacing: 12) {
                        Text("\(coin.name ?? ("Official " + coin.symbol.uppercased())) Details")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 10)

                        timeframePicker

                        if isSupportedSymbol(coin.symbol) {
                            TradingViewWebView(
                                symbol: parseBinancePair(coin.symbol),
                                timeframe: timeframe.rawValue
                            )
                            .aspectRatio(16/9, contentMode: .fit)
                            .clipped()
                        } else {
                            VStack {
                                Text("Chart Not Supported for \(coin.symbol.uppercased())")
                                    .foregroundColor(.gray)
                            }
                            .frame(height: 260)
                        }

                        marketStatsSection

                        aiInsightsSection

                        watchlistButton

                        if let tradeVM = tradeVM {
                            tradeButton(tradeVM: tradeVM)
                        }

                        Spacer().frame(height: 10)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitle("\(coin.symbol.uppercased())", displayMode: .inline)
    }

    private var timeframePicker: some View {
        Picker("Timeframe", selection: $timeframe) {
            Text("1H").tag(TradeTimeframe.oneHour)
            Text("1D").tag(TradeTimeframe.oneDay)
            Text("1W").tag(TradeTimeframe.oneWeek)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }

    private var marketStatsSection: some View {
        CardView(cornerRadius: 6, paddingAmount: 6) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Market Stats")
                    .font(.headline)
                    .foregroundColor(.white)
                Divider().background(Color.gray)

                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        let high = coin.high24h ?? 0
                        let low  = coin.low24h ?? 0
                        let change = coin.priceChangePercentage24h ?? 0
                        Text("24H High: $\(high, specifier: "%.2f")")
                            .foregroundColor(.white)
                        Text("24H Low: $\(low, specifier: "%.2f")")
                            .foregroundColor(.white)
                        Text("Price Change (24h): \(change, specifier: "%.2f")%")
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        let volume = coin.totalVolume ?? 0
                        let mcap   = coin.marketCap ?? 0
                        let supply = coin.circulatingSupply ?? 0
                        Text("Volume: $\(volume, specifier: "%.0f")")
                            .foregroundColor(.white)
                        Text("Market Cap: $\(mcap, specifier: "%.0f")")
                            .foregroundColor(.white)
                        Text("Circ. Supply: \(supply, specifier: "%.0f")")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private var aiInsightsSection: some View {
        CardView(cornerRadius: 6, paddingAmount: 6) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AI Insights (Placeholder)")
                    .font(.headline)
                    .foregroundColor(.white)
                Divider().background(Color.gray)
                Text("Coming soon! This is where Kevin’s LLM might provide insights on \(coin.symbol.uppercased()).")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
    }

    private var watchlistButton: some View {
        Button {
            if homeVM.watchlistIDs.contains(coin.coinGeckoID) {
                homeVM.removeFromWatchlist(coinID: coin.coinGeckoID)
            } else {
                homeVM.addToWatchlist(coinID: coin.coinGeckoID)
            }
            homeVM.refreshWatchlistData()
        } label: {
            Text(homeVM.watchlistIDs.contains(coin.coinGeckoID)
                 ? "Remove from Watchlist"
                 : "Add to Watchlist")
                .font(.headline)
                .padding()
                .background(homeVM.watchlistIDs.contains(coin.coinGeckoID)
                            ? Color.red.opacity(0.8)
                            : Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func tradeButton(tradeVM: TradeViewModel) -> some View {
        Button {
            tradeVM.selectedSymbol = coin.symbol.uppercased() + "-USD"
            UIApplication.safeEndEditing()
            appState.selectedTab = .trade
        } label: {
            Text("Trade \(coin.symbol.uppercased())")
                .font(.headline)
                .padding()
                .background(Color.green.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    func parseBinancePair(_ rawSymbol: String) -> String {
        let upper = rawSymbol.uppercased()
        if upper.contains("USD") {
            return "BINANCE:\(upper.replacingOccurrences(of: "-", with: ""))"
        }
        return "BINANCE:\(upper)USDT"
    }

    func isSupportedSymbol(_ symbol: String) -> Bool {
        let supportedSet: Set<String> = [
            "BTC","ETH","SOL","XRP","BNB","DOGE","ADA","APT","ARB","TRX",
            "MATIC","DOT","SHIB","LINK","LTC","BCH","ATOM","FIL","AVAX",
            "UNI","XLM","SUI","PEPE","OP","QNT","GRT","ALGO","ICP","VET",
            "FTM","NEAR","AAVE","WBTC","TUSD","USDC","USDT","BUSD","DAI"
        ]
        return supportedSet.contains(symbol.uppercased())
    }
}