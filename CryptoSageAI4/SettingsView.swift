//
//  SettingsView.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var appState: AppState

    @State private var notificationsEnabled = true
    @State private var priceAlertsEnabled = false

    @State private var selectedCurrency = "USD"
    @State private var aiTuning = "Conservative"

    @State private var showLinkSheet = false
    @State private var showAdvancedExchange = false

    @State private var aiPersonality: Double = 0.5

    var body: some View {
        Form {
            Section(header: Text("General").foregroundColor(.white)) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                Toggle("Dark Mode On?", isOn: $appState.isDarkMode)
            }

            Section(header: Text("Price Alerts").foregroundColor(.white)) {
                Toggle("Enable Price Alerts", isOn: $priceAlertsEnabled)
                if priceAlertsEnabled {
                    Text("You can configure custom alerts in the future.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            }

            Section(header: Text("Preferences").foregroundColor(.white)) {
                Picker("Currency Preference", selection: $selectedCurrency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("BTC").tag("BTC")
                }
                .pickerStyle(.segmented)

                Picker("AI Trading Style", selection: $aiTuning) {
                    Text("Aggressive").tag("Aggressive")
                    Text("Conservative").tag("Conservative")
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Text("AI Personality").foregroundColor(.white)
                    Slider(value: $aiPersonality, in: 0.0...1.0, step: 0.1)
                    Text("Value: \(aiPersonality, specifier: "%.1f") (placeholder)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }

            Section(header: Text("Connected Exchanges").foregroundColor(.white)) {
                // For now, we assume no real linked accounts
                Text("No exchanges linked.")
                    .foregroundColor(.gray)

                Button {
                    showLinkSheet = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Link New Exchange")
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
                }
            }

            Section(header: Text("Advanced Exchange Settings").foregroundColor(.white)) {
                Toggle("Show Advanced Exchange Options", isOn: $showAdvancedExchange)
                if showAdvancedExchange {
                    Text("Future expansions: real trading, API key usage, etc.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            }

            Section(header: Text("Wallets").foregroundColor(.white)) {
                NavigationLink(destination: WalletsView().environmentObject(homeVM)) {
                    Text("Manage Wallets")
                }
            }

            Section(footer:
                Text("Additional preferences can go here, like region, advanced AI settings, etc.")
                    .foregroundColor(.gray)
            ) {
                EmptyView()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .foregroundColor(.white)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLinkSheet) {
            LinkExchangeView { newExchange in
                // we do nothing for now
                print("Linked exchange: \(newExchange)")
            }
        }
    }
}

struct LinkExchangeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var exchangeName = ""
    @State private var apiKey = ""
    @State private var apiSecret = ""

    let onLink: (String) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exchange Info")) {
                    TextField("Exchange Name", text: $exchangeName)
                    TextField("API Key", text: $apiKey)
                    SecureField("API Secret", text: $apiSecret)
                }

                Button("Link Exchange") {
                    guard !exchangeName.isEmpty else { return }
                    onLink(exchangeName)
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(8)
                .background(Color.green.opacity(0.8))
                .cornerRadius(8)
            }
            .navigationTitle("Link Exchange")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}