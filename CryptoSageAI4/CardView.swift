//
//  CardView.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 8
    var paddingAmount: CGFloat = 8
    
    init(cornerRadius: CGFloat = 8,
         paddingAmount: CGFloat = 8,
         @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.paddingAmount = paddingAmount
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding(paddingAmount)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(cornerRadius)
        .shadow(color: Color.white.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}