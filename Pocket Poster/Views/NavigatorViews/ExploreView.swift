//
//  ExploreView.swift
//  Pocket Poster
//
//  Created by lemin on 7/6/25.
//

import SwiftUI

struct ExploreView: View {
    @State private var isLoading = true
    @State private var error: Error? = nil
    
#if DEBUG
    @AppStorage("exploreLink") var exploreLink: String = DownloadManager.exploreLink
#endif
    
    var body: some View {
        ZStack {
#if DEBUG
            let websiteURL = URL(string: exploreLink)
#else
            let websiteURL = URL(string: DownloadManager.exploreLink)
#endif
            if let error = error {
                VStack {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                    Button(action: {
                        isLoading = true
                        self.error = nil
                    }) {
                        Text("Retry")
                    }
                }
            } else if let url = websiteURL {
                WallpaperWebView(url, isLoading: $isLoading, error: $error)
                if isLoading {
                    ProgressView()
                }
            } else {
                Text("Failed to load explore page.")
            }
        }
    }
}
