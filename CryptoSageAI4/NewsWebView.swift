//
//  NewsWebView.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//

import SwiftUI
import WebKit

struct NewsWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear

        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
