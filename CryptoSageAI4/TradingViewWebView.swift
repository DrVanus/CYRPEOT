//
//  TradingViewWebView.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI
import WebKit

struct TradingViewWebView: UIViewRepresentable {
    let symbol: String
    var timeframe: String? = nil

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        loadChart(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadChart(into: uiView)
    }

    private func loadChart(into webView: WKWebView) {
        let interval = timeframe ?? "30"

        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body {
                margin:0;
                padding:0;
                background-color:#000000;
              }
            </style>
        </head>
        <body>
          <div id="tradingview_widget"></div>
          <script src="https://s3.tradingview.com/tv.js"></script>
          <script>
          new TradingView.widget({
            "width": "100%",
            "height": "100%",
            "symbol": "\(symbol)",
            "interval": "\(interval)",
            "timezone": "Etc/UTC",
            "theme": "dark",
            "style": "1",
            "locale": "en",
            "enable_publishing": false,
            "hide_top_toolbar": true,
            "hide_legend": false,
            "save_image": false,
            "container_id": "tradingview_widget"
          });
          </script>
        </body>
        </html>
        """

        webView.loadHTMLString(htmlString, baseURL: nil)
    }
}