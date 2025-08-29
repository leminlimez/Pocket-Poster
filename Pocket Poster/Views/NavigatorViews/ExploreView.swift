//
//  ExploreView.swift
//  Pocket Poster
//
//  Created by lemin on 7/6/25.
//

import SwiftUI
import CachedAsyncImage

let MIN_SIZE: CGFloat = 165
let CORNER_RADIUS: CGFloat = 12

struct ExploreView: View {
    @ObservedObject var cowabungaAPI = CowabungaAPI.shared
    
    // lazyvgrid
    @State private var gridItemLayout = [GridItem(.adaptive(minimum: MIN_SIZE))]
    @State private var wallpapers: [DownloadableWallpaper] = []
    
    @State var wallpaperTypeSelected = 0
    @State var wallpaperTypeShown = DownloadableWallpaper.WallpaperType.custom
    
    @State var filterType: FilterType = .random
    @State var searchTerm: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                    // refresh
                    wallpapers.removeAll()
                    Haptic.shared.play(.light)
                    //URLCache.imageCache.removeAllCachedResponses()
                    loadWallpapers()
                }
                VStack {
                    Picker("", selection: $wallpaperTypeSelected) {
                        Text("Custom").tag(0)
                        Text("Apple").tag(1)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
                
                if wallpapers.isEmpty {
                    ProgressView()
                        .scaleEffect(1.75)
                        .navigationTitle("Explore")
                } else {
                    LazyVGrid(columns: gridItemLayout) {
                        ForEach(wallpapers) { wallpaper in
                            if searchTerm == "" || wallpaper.name.lowercased().contains(searchTerm.lowercased()) || (wallpaper.authors ?? "").lowercased().contains(searchTerm.lowercased()) {
                                Button(action: {
                                    DownloadManager.shared.startTendiesDownload(for: cowabungaAPI.getDownloadURLForWallpaper(wallpaper: wallpaper))
                                }) {
                                    VStack(spacing: 0) {
                                        ZStack {
                                            Color.gray.opacity(0.4)
                                            if wallpaper.previewIsGif() {
                                                GIFImage(url: cowabungaAPI.getPreviewURLForWallpaper(wallpaper: wallpaper), animate: true, loop: true)
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(maxWidth: .infinity)
                                            } else {
                                                CachedAsyncImage(url: cowabungaAPI.getPreviewURLForWallpaper(wallpaper: wallpaper), urlCache: .imageCache) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(maxWidth: .infinity)
                                                } placeholder: {
                                                    Color.gray
                                                        .frame(height: MIN_SIZE)
                                                }
                                            }
                                        }
                                        .cornerRadius(CORNER_RADIUS, corners: .topLeft)
                                        .cornerRadius(CORNER_RADIUS, corners: .topRight)
                                        HStack {
                                            VStack(spacing: 4) {
                                                HStack {
                                                    Text(wallpaper.name)
                                                        .foregroundStyle(Color(uiColor: .label))
                                                        .minimumScaleFactor(0.5)
                                                    Spacer()
                                                }
                                                if let authors = wallpaper.authors {
                                                    HStack {
                                                        Text(authors)
                                                            .foregroundColor(.secondary)
                                                            .font(.caption)
                                                            .minimumScaleFactor(0.5)
                                                        Spacer()
                                                    }
                                                }
                                            }
                                            .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "arrow.down.circle")
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(height: 58)
                                    }
                                }
                                .frame(minWidth: MIN_SIZE)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(CORNER_RADIUS)
                                .padding(4)
                            }
                        }
                    }
                    .padding()
                }
            }
            .searchable(text: $searchTerm)
            .coordinateSpace(name: "pullToRefresh")
            .navigationTitle("Explore")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterChangerPopup()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .onAppear {
            loadWallpapers()
        }
        .onChange(of: wallpaperTypeSelected) { newValue in
            let map = [0: DownloadableWallpaper.WallpaperType.custom, 1: .apple, 2: .template]
            wallpaperTypeShown = map[newValue]!
            
            wallpapers.removeAll()
            loadWallpapers()
        }
    }
    
    func loadWallpapers() {
        Task {
            do {
                wallpapers = try await cowabungaAPI.fetchWallpapers(type: wallpaperTypeShown)
                wallpapers = cowabungaAPI.filterWallpapers(wallpapers: wallpapers, filterType: filterType)
            } catch {
                UIApplication.shared.alert(title: NSLocalizedString("Failed to fetch wallpapers", comment: ""), body: error.localizedDescription)
            }
        }
    }
    
    func showFilterChangerPopup() {
        // create and configure alert controller
        let alert = UIAlertController(title: NSLocalizedString("Filter Wallpapers", comment: ""), message: "", preferredStyle: .actionSheet)
        
        // create the actions
        for type in FilterType.allCases {
            let newAction = UIAlertAction(title: type.rawValue, style: .default) { (action) in
                // apply the filter type
                filterType = type
                wallpapers.removeAll()
                loadWallpapers()
            }
            if filterType == type {
                // add a check mark
                newAction.setValue(true, forKey: "checked")
            }
            alert.addAction(newAction)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
            // cancels the action
        }
        
        // add the actions
        alert.addAction(cancelAction)
        
        let view: UIView = UIApplication.shared.windows.first!.rootViewController!.view
        // present popover for iPads
        alert.popoverPresentationController?.sourceView = view // prevents crashing on iPads
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 0, height: 0) // show up at center bottom on iPads
        
        // present the alert
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
}

struct PullToRefresh: View {
    var coordinateSpaceName: String
    var onRefresh: ()->Void
    
    @State var needRefresh: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            if (geo.frame(in: .named(coordinateSpaceName)).midY > 50) {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if (geo.frame(in: .named(coordinateSpaceName)).maxY < 10) {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            onRefresh()
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView()
                        .scaleEffect(1.75)
                        .onAppear {
                            Haptic.shared.play(.light)
                        }
                } else {
                    Text("")
                }
                Spacer()
            }
        }.padding(.top, -50)
    }
}
