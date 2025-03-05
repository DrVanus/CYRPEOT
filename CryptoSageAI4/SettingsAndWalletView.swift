//
//  UserWallet.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI

struct UserWallet: Identifiable, Codable {
    let id = UUID()
    let address: String
    let label: String
}

struct WalletsView: View {
    @EnvironmentObject var homeVM: HomeViewModel

    @State private var newLabel   = ""
    @State private var newAddress = ""

    var body: some View {
        VStack {
            Text("Your Wallets")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top, 10)

            if homeVM.userWallets.isEmpty {
                Text("No wallets yet.")
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            } else {
                List {
                    ForEach(homeVM.userWallets) { w in
                        VStack(alignment: .leading) {
                            Text(w.label)
                                .foregroundColor(.white)
                                .font(.headline)
                            Text(w.address)
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                        .listRowBackground(Color.black)
                    }
                    .onDelete { indexSet in
                        homeVM.userWallets.remove(atOffsets: indexSet)
                        homeVM.saveUserWallets()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }

            HStack {
                TextField("Label", text: $newLabel)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)

                TextField("Address", text: $newAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Add") {
                    guard !newAddress.isEmpty else { return }
                    let wallet = UserWallet(address: newAddress, label: newLabel.isEmpty ? "Wallet" : newLabel)
                    homeVM.userWallets.append(wallet)
                    homeVM.saveUserWallets()

                    newAddress = ""
                    newLabel   = ""
                }
                .padding(6)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Manage Wallets")
        .navigationBarTitleDisplayMode(.inline)
    }
}