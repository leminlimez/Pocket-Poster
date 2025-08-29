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
    @Binding var isLoading: Bool
    @Binding var error: Error?
    
    init(_ url: URL, isLoading: Binding<Bool>, error: Binding<Error?>) {
        self.url = url
        self._isLoading = isLoading
        self._error = error
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> some UIView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(AssetsSchemeHandler(), forURLScheme: "pocketposter")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WallpaperWebView
        init(_ parent: WallpaperWebView) {
            self.parent = parent
        }
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            return
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled { return }
            print("loading error: \(error)")
            parent.isLoading = false
            parent.error = error
        }
    }
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
