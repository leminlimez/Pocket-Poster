//
//  WebView.swift
//  Pocket Poster
//
//  Created by lemin on 7/6/25.
//

import Foundation
import SwiftUI
import WebKit

struct WallpaperWebView: UIViewRepresentable {
    let url: URL
    
    init(_ url: URL) {
        self.url = url
    }
    
    func makeUIView(context: Context) -> some UIView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(AssetsSchemeHandler(), forURLScheme: "pocketposter")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}


class AssetsSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        DispatchQueue.global().async {
            print("handling scheme")
            guard let url = urlSchemeTask.request.url, url.absoluteString.starts(with: "pocketposter://download") else { return }
            
            print("url: \(url.absoluteString)")
            DownloadManager.shared.startTendiesDownload(for: url)
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        
    }
}
