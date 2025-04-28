//
//  GlobalSummaryView.swift
//  CSAI1
//

import SwiftUI

struct GlobalSummaryView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    @State private var refreshTimer = Timer
        .publish(every: 15, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        Group {
            if let global = marketVM.globalData {
                ScrollView(.horizontal, showsIndicators: false) {
                    rowOfChips(global)
                        .padding(.horizontal, 16)
                }
            } else {
                Text("Loading global market data...")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            Task {
                await marketVM.fetchGlobalData()
            }
        }
        .onReceive(refreshTimer) { _ in
            Task {
                await marketVM.fetchGlobalData()
            }
        }
    }

    // MARK: - Single Row of “Chips”
    @ViewBuilder
    private func rowOfChips(_ global: GlobalMarketData) -> some View {
        HStack(spacing: 0) {
            statChip(
                label: "Market Cap",
                value: global.totalMarketCap["usd"],
                icon: "dollarsign.circle"
            )
            divider()
            statChip(
                label: "24h Volume",
                value: global.totalVolume["usd"],
                icon: "chart.bar.fill"
            )
            divider()
            statChip(
                label: "BTC Dominance",
                value: global.marketCapPercentage["btc"],
                suffix: "%",
                isPercent: true,
                icon: "bitcoinsign.circle"
            )
            divider()
            statChip(
                label: "ETH Dominance",
                value: global.marketCapPercentage["eth"],
                suffix: "%",
                isPercent: true,
                icon: "chart.bar.xaxis"
            )
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    // MARK: - Stat “Chip”
    @ViewBuilder
    private func statChip(label: String,
                          value: Double?,
                          suffix: String = "",
                          isPercent: Bool = false,
                          icon: String = "") -> some View {

        let isNil = (value == nil)
        let raw = value ?? 0
        let displayText = isNil
            ? "--"
            : isPercent
                ? String(format: "%.2F", raw) + suffix
                : raw.formattedWithAbbreviations() + suffix

        let color: Color = {
            guard isPercent, !isNil else { return .primary }
            return raw >= 0 ? .green : .red
        }()

        VStack(spacing: 2) {
            HStack(spacing: 2) {
                if !icon.isEmpty {
                    let chosenIcon: String = (label == "24h Change")
                        ? (raw >= 0 ? "arrow.up.right" : "arrow.down.right")
                        : icon
                    Image(systemName: chosenIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(.gray)
                }
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
            }
            Text(displayText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44, alignment: .center)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Vertical Divider
    private func divider() -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(width: 0.5, height: 24)
    }
}
