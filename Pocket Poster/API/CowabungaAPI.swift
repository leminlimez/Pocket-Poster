//
//  CowabungaAPI.swift
//  Pocket Poster
//
//  Created by lemin on 7/15/25.
//

import UIKit

enum FilterType: String, CaseIterable {
    case random = "Random"
    case newest = "Newest"
    case oldest = "Oldest"
}

class CowabungaAPI: ObservableObject {
    
    static let shared = CowabungaAPI()
    
    var serverURL = ""
    var session = URLSession.shared
    
    func fetchWallpapers(type: DownloadableWallpaper.WallpaperType) async throws -> [DownloadableWallpaper] {
        let request = URLRequest(url: .init(string: serverURL + "wallpapers-\(type.rawValue).json")!)
        
        let (data, response) = try await session.data(for: request) as! (Data, HTTPURLResponse)
        guard response.statusCode == 200 else { throw APIError.connectionFailed }
        let wallpapers = try JSONDecoder().decode([DownloadableWallpaper].self, from: data)
        
        for i in wallpapers.indices {
            wallpapers[i].type = type
        }
        
        return wallpapers
    }
    
    func filterWallpapers(wallpapers: [DownloadableWallpaper], filterType: FilterType) -> [DownloadableWallpaper] {
        var filtered = wallpapers
        if filterType == FilterType.newest {
            filtered = filtered.reversed()
        } else if filterType == FilterType.random {
            filtered = filtered.shuffled()
        }
        return filtered
    }
    
    func getCommitHash() async throws -> String {
        let request = URLRequest(url: .init(string: serverURL + "https://api.github.com/repos/SerStars/nugget-wallpapers/commits/main")!)
        
        let (data, response) = try await session.data(for: request) as! (Data, HTTPURLResponse)
        guard response.statusCode == 200 else { throw APIError.connectionFailed }
        guard let repoinfo = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { throw APIError.repoHashError }
        guard let hash = repoinfo["sha"] as? String else { throw APIError.repoHashError }
        return hash
    }
    
    func getDownloadURLForWallpaper(wallpaper: DownloadableWallpaper) -> URL {
        if wallpaper.url.hasPrefix("https://") {
            URL(string: wallpaper.url)!
        } else {
            URL(string: serverURL + wallpaper.url)!
        }
    }
    
    func getPreviewURLForWallpaper(wallpaper: DownloadableWallpaper) -> URL {
        URL(string: serverURL + wallpaper.preview)!
    }
    
    init() {
        Task {
            do {
                let hash = try await getCommitHash()
                serverURL = "https://raw.githubusercontent.com/SerStars/nugget-wallpapers/\(hash)/"
            } catch {
                 await UIApplication.shared.alert(body: error.localizedDescription)
            }
        }
    }
}
