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
    
    var body: some View {
        ZStack {
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
            } else if let url = URL(string: "https://cowabun.ga/wallpapers?pocketposter=true") {
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
