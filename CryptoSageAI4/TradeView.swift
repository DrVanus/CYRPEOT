//
//  TradeTimeframe.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI

enum TradeTimeframe: String {
    case oneHour = "60"
    case oneDay  = "D"
    case oneWeek = "W"
}

struct TradeView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var tradeVM: TradeViewModel

    @State private var selectedTimeframe: TradeTimeframe = .oneHour
    @State private var showAdvancedTrading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        timeframeSegment

                        TradingViewWebView(symbol: parseBinancePair(tradeVM.selectedSymbol),
                                           timeframe: tradeVM.chartTimeframe)
                            .aspectRatio(16/9, contentMode: .fit)
                            .clipped()

                        orderPlacementSection

                        Toggle("Show Advanced Trading", isOn: $showAdvancedTrading)
                            .padding(.horizontal)
                            .foregroundColor(.white)

                        if showAdvancedTrading {
                            advancedSection
                        }

                        Spacer().frame(height: 80)
                    }
                }
            }
            .navigationBarTitle("Trade", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var orderPlacementSection: some View {
        CardView(cornerRadius: 6, paddingAmount: 6) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Place an Order")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Balance: $\(tradeVM.userBalance, specifier: "%.2f")")
                    .foregroundColor(.white)
                    .font(.subheadline)

                HStack {
                    Picker("Symbol", selection: $tradeVM.selectedSymbol) {
                        Text("BTC-USD").tag("BTC-USD")
                        Text("ETH-USD").tag("ETH-USD")
                        Text("SOL-USD").tag("SOL-USD")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Picker("Side", selection: $tradeVM.side) {
                        Text("Buy").tag("Buy")
                        Text("Sell").tag("Sell")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Picker("Order Type", selection: $tradeVM.orderType) {
                    Text("Market").tag("Market")
                    Text("Limit").tag("Limit")
                    Text("Stop-Limit").tag("Stop-Limit")
                    Text("Trailing Stop").tag("Trailing Stop")
                }
                .pickerStyle(SegmentedPickerStyle())

                HStack {
                    Text("Qty:")
                        .foregroundColor(.white)
                    TextField("0.0", text: $tradeVM.quantity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }

                if tradeVM.orderType == "Limit" || tradeVM.orderType == "Stop-Limit" {
                    HStack {
                        Text("Limit Price:")
                            .foregroundColor(.white)
                        TextField("0.0", text: $tradeVM.limitPrice)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                if tradeVM.orderType == "Stop-Limit" {
                    HStack {
                        Text("Stop Price:")
                            .foregroundColor(.white)
                        TextField("0.0", text: $tradeVM.stopPrice)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                if tradeVM.orderType == "Trailing Stop" {
                    HStack {
                        Text("Trailing Stop:")
                            .foregroundColor(.white)
                        TextField("0.0", text: $tradeVM.trailingStop)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }

                // Quick % buttons
                HStack {
                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                        Button {
                            tradeVM.applyFraction(fraction)
                        } label: {
                            Text("\(Int(fraction * 100))%")
                                .font(.subheadline)
                                .padding(6)
                                .frame(minWidth: 40)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }

                Button {
                    tradeVM.submitOrder()
                } label: {
                    Text("\(tradeVM.side) \(tradeVM.selectedSymbol)")
                        .font(.headline)
                        .padding()
                        .background(tradeVM.side == "Buy" ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                if !tradeVM.aiSuggestion.isEmpty {
                    Text(tradeVM.aiSuggestion)
                        .foregroundColor(.yellow)
                        .font(.subheadline)
                }
            }
        }
        .background(
            tradeVM.side == "Buy"
                ? Color.green.opacity(0.05)
                : Color.red.opacity(0.05)
        )
    }

    private var advancedSection: some View {
        VStack(spacing: 12) {
            CardView(cornerRadius: 6, paddingAmount: 6) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Order Book (Placeholder)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Divider().background(Color.gray)

                    let randomBids = (1...5).map { _ in (price: Double.random(in: 9700...9800), qty: Double.random(in: 0.1...1.0)) }
                    let randomAsks = (1...5).map { _ in (price: Double.random(in: 9800...9900), qty: Double.random(in: 0.1...1.0)) }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bids").foregroundColor(.green)
                            ForEach(randomBids, id: \.price) { bid in
                                Text(String(format: "Price: %.2f, Qty: %.2f", bid.price, bid.qty))
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Asks").foregroundColor(.red)
                            ForEach(randomAsks, id: \.price) { ask in
                                Text(String(format: "Price: %.2f, Qty: %.2f", ask.price, ask.qty))
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }

            CardView(cornerRadius: 6, paddingAmount: 6) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Depth Chart (Placeholder)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Divider().background(Color.gray)

                    GeometryReader { geo in
                        ZStack {
                            Path { path in
                                path.move(to: .zero)
                                path.addLine(to: CGPoint(x: geo.size.width * 0.4, y: geo.size.height * 0.6))
                                path.addLine(to: CGPoint(x: geo.size.width * 0.4, y: geo.size.height))
                                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                                path.closeSubpath()
                            }
                            .fill(Color.red.opacity(0.3))

                            Path { path in
                                path.move(to: CGPoint(x: geo.size.width, y: 0))
                                path.addLine(to: CGPoint(x: geo.size.width * 0.6, y: geo.size.height * 0.4))
                                path.addLine(to: CGPoint(x: geo.size.width * 0.6, y: geo.size.height))
                                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                                path.closeSubpath()
                            }
                            .fill(Color.green.opacity(0.3))
                        }
                    }
                    .frame(height: 120)
                }
                .frame(maxHeight: 180)
            }

            CardView(cornerRadius: 6, paddingAmount: 6) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Exchange Trading Integration (Placeholder)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Divider().background(Color.gray)
                    Text("In the future, integrate real exchange APIs (Binance, Coinbase, etc.) to place orders here.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            }
        }
    }

    @ViewBuilder
    private var timeframeSegment: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            Text("1H").tag(TradeTimeframe.oneHour)
            Text("1D").tag(TradeTimeframe.oneDay)
            Text("1W").tag(TradeTimeframe.oneWeek)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onChange(of: selectedTimeframe) { newVal in
            tradeVM.chartTimeframe = newVal.rawValue
        }
    }

    func parseBinancePair(_ raw: String) -> String {
        let noDash = raw.uppercased().replacingOccurrences(of: "-", with: "")
        let removedUsd = noDash.replacingOccurrences(of: "USD", with: "")
        return "BINANCE:\(removedUsd)USDT"
    }
}