//
//  CustomTabBar 2.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI

struct CustomTabBar: View {
    @EnvironmentObject var appState: AppState
    let tabs: [CustomTab] = [.home, .market, .trade, .portfolio, .ai]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 16)
        .background(Color.black.opacity(0.9))
    }

    @ViewBuilder
    func tabButton(_ tab: CustomTab) -> some View {
        Button(action: { appState.selectedTab = tab }) {
            VStack(spacing: 2) {
                switch tab {
                case .home:
                    Image(systemName: "house.fill")
                case .market:
                    Image(systemName: "chart.bar.xaxis")
                case .trade:
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                case .portfolio:
                    Image(systemName: "chart.pie.fill")
                case .ai:
                    Image(systemName: "sparkles")
                }
                .font(.system(size: 18, weight: .semibold))

                Text(tab.rawValue).font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(appState.selectedTab == tab ? .blue : .gray)
        }
    }
}