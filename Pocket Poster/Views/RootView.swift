//
//  RootView.swift
//  Pocket Poster
//
//  Created by lemin on 6/11/25.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            VideoView()
                .tabItem {
                    Label("Videos", systemImage: "camera")
                }
            CarPlayView()
                .tabItem {
                    Label("CarPlay", systemImage: "car")
                }
        }
    }
}
