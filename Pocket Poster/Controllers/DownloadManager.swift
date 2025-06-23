//
//  DownloadManager.swift
//  Pocket Poster
//
//  Created by lemin on 6/1/25.
//

import Foundation

class DownloadManager {
    static func getWallpaperNameFromURL(string url: String) -> String {
        return String(url.split(separator: "/").last ?? "Unknown")
    }
    
    static func downloadFromURL(_ url: URL) async throws -> URL {
        print("Downloading from \(url.absoluteString)")
        
        let request = URLRequest(url: url)
            
        let (data, response) = try await URLSession.shared.data(for: request) as! (Data, HTTPURLResponse)
        guard response.statusCode == 200 else { throw URLError(.cannotConnectToHost) }
        let newURL = PosterBoardManager.shared.getTendiesStoreURL().appendingPathComponent(getWallpaperNameFromURL(string: url.absoluteString))
        try data.write(to: newURL)
        return newURL
    }
    
    static func downloadFromURL(string path: String) async throws -> URL {
        guard let url = URL(string: path) else { throw URLError(.unknown) }
        return try await downloadFromURL(url)
    }
    
    static func copyTendies(from url: URL) throws -> URL {
        // scope the resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let newURL = PosterBoardManager.shared.getTendiesStoreURL().appendingPathComponent(url.lastPathComponent)
        try FileManager.default.copyItem(at: url, to: newURL)
        return newURL
    }
}
