//
//  ExploreView.swift
//  Pocket Poster
//
//  Created by lemin on 7/6/25.
//

import SwiftUI

struct ExploreView: View {
    var body: some View {
        WallpaperWebView(URL(string: "https://cowabun.ga/wallpapers?pocketposter=true")!)
    }
}
