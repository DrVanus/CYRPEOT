//
//  MarketSortOption.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//

import SwiftUI

enum MarketSortOption {
    case name, price, change
}

struct MarketView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var marketVM: MarketViewModel
    @ObservedObject var homeVM: HomeViewModel
    @ObservedObject var tradeVM: TradeViewModel

    @State private var searchText = ""
    @State private var sortOption: MarketSortOption = .name
    @State private var includeSolana = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        Toggle("Include Solana (DexScreener)", isOn: $includeSolana)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .foregroundColor(.white)

                        HStack {
                            TextField("Search coins...", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.leading)
                                .padding(.vertical, 6)

                            Spacer()

                            Menu("Sort By") {
                                Button("Name") { sortOption = .name }
                                Button("Price") { sortOption = .price }
                                Button("24h %") { sortOption = .change }
                            }
                            .padding(.trailing, 8)
                            .foregroundColor(.white)
                        }

                        if marketVM.isLoading {
                            Text("Loading market data...")
                                .foregroundColor(.gray)
                                .padding()
                            Spacer()
                        } else {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Fav")
                                        .foregroundColor(.gray)
                                        .frame(width: 32)
                                    Text("Coin")
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("Price")
                                        .foregroundColor(.gray)
                                        .frame(width: 70, alignment: .trailing)
                                    Text("24h")
                                        .foregroundColor(.gray)
                                        .frame(width: 50, alignment: .trailing)
                                    Text("Volume")
                                        .foregroundColor(.gray)
                                        .frame(width: 70, alignment: .trailing)
                                    Text("High/Low")
                                        .foregroundColor(.gray)
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.vertical, 4)
                                .background(Color.black)

                                Divider().background(Color.gray)

                                if sortedCoins.isEmpty {
                                    VStack {
                                        Text("No coins match your search.")
                                            .foregroundColor(.gray)
                                            .padding()
                                    }
                                } else {
                                    ForEach(sortedCoins, id: \.coinGeckoID) { coin in
                                        VStack(spacing: 0) {
                                            HStack {
                                                Image(systemName: homeVM.watchlistIDs.contains(coin.coinGeckoID) ? "star.fill" : "star")
                                                    .foregroundColor(homeVM.watchlistIDs.contains(coin.coinGeckoID) ? .yellow : .gray)
                                                    .frame(width: 32)
                                                    .onTapGesture {
                                                        if homeVM.watchlistIDs.contains(coin.coinGeckoID) {
                                                            homeVM.removeFromWatchlist(coinID: coin.coinGeckoID)
                                                        } else {
                                                            homeVM.addToWatchlist(coinID: coin.coinGeckoID)
                                                        }
                                                        homeVM.refreshWatchlistData()
                                                    }

                                                NavigationLink {
                                                    CoinDetailView(
                                                        coin: coin,
                                                        homeVM: homeVM,
                                                        tradeVM: tradeVM
                                                    )
                                                    .navigationBarBackButtonHidden(false)
                                                } label: {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(coin.symbol.uppercased())
                                                            .foregroundColor(.white)
                                                            .fontWeight(.semibold)
                                                        Text(coin.name ?? "")
                                                            .foregroundColor(.gray)
                                                            .font(.caption2)
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                }

                                                Text("$\(coin.currentPrice ?? 0, specifier: "%.2f")")
                                                    .foregroundColor(.white)
                                                    .frame(width: 70, alignment: .trailing)

                                                let change = coin.priceChangePercentage24h ?? 0
                                                Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f")%")
                                                    .foregroundColor(change >= 0 ? .green : .red)
                                                    .frame(width: 50, alignment: .trailing)

                                                Text("$\(Int(coin.totalVolume ?? 0))")
                                                    .foregroundColor(.white)
                                                    .frame(width: 70, alignment: .trailing)

                                                let high = coin.high24h ?? 0
                                                let low  = coin.low24h ?? 0
                                                Text("\(String(format: "%.2f", high))/\(String(format: "%.2f", low))")
                                                    .foregroundColor(.white)
                                                    .frame(width: 80, alignment: .trailing)
                                            }
                                            .padding(.vertical, 4)
                                            .background(Color.black)

                                            Divider().background(Color.gray.opacity(0.4))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            Spacer().frame(height: 80)
                        }
                    }
                }
                .refreshable {
                    marketVM.fetchMarketCoins()
                }
            }
            .navigationBarTitle("Market", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    var sortedCoins: [CoinGeckoCoin] {
        let filtered = marketVM.marketCoins.filter {
            searchText.isEmpty ||
            $0.symbol.lowercased().contains(searchText.lowercased()) ||
            ($0.name?.lowercased().contains(searchText.lowercased()) ?? false)
        }
        switch sortOption {
        case .name:
            return filtered.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .price:
            return filtered.sorted { ($0.currentPrice ?? 0) > ($1.currentPrice ?? 0) }
        case .change:
            return filtered.sorted { ($0.priceChangePercentage24h ?? 0) > ($1.priceChangePercentage24h ?? 0) }
        }
    }
}
