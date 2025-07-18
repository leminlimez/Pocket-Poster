//
//  DownloadManager.swift
//  Pocket Poster
//
//  Created by lemin on 6/1/25.
//

import Foundation
import UIKit

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    static let exploreLink = "https://cowabun.ga/wallpapers?pocketposter=true"
    
    @Published var downloadURL: String? = nil
    
    func getWallpaperNameFromURL(string url: String) -> String {
        return String(url.split(separator: "/").last ?? "Unknown")
    }
    
    func startTendiesDownload(for url: URL) {
        // prohibit to only tendies files
        if !url.absoluteString.hasSuffix(".tendies") {
            UIApplication.shared.alert(body: NSLocalizedString("Only .tendies files can be downloaded!", comment: ""))
        } else if PosterBoardManager.shared.selectedTendies.count >= PosterBoardManager.MaxTendies {
            UIApplication.shared.alert(title: NSLocalizedString("Max Tendies Reached", comment: ""), body: String(format: NSLocalizedString("You can only apply %@ descriptors.", comment: ""), "\(PosterBoardManager.MaxTendies)"))
        } else {
            DispatchQueue.main.async {
                self.downloadURL = url.absoluteString.replacingOccurrences(of: "pocketposter://download?url=", with: "")
                UIApplication.shared.confirmAlert(title: NSLocalizedString("Download Tendies File", comment: ""), body: String(format: NSLocalizedString("Would you like to download the file %@?", comment: ""), "\(self.getWallpaperNameFromURL(string: self.downloadURL ?? "/Unknown"))"), onOK: {
                    self.downloadWallpaper()
                }, noCancel: false)
            }
        }
    }
    
    func downloadWallpaper() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        UIApplication.shared.alert(title: NSLocalizedString("Downloading", comment: "") + " \(getWallpaperNameFromURL(string: downloadURL ?? "/Unknown"))...", body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)
        
        Task {
            do {
                let newURL = try await downloadFromURL(string: downloadURL!)
                DispatchQueue.main.async {
                    PosterBoardManager.shared.selectedTendies.append(newURL)
                    Haptic.shared.notify(.success)
                    UIApplication.shared.dismissAlert(animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                        UIApplication.shared.alert(title: NSLocalizedString("Successfully downloaded wallpaper!", comment: ""), body: NSLocalizedString("Your downloaded .tendies will be on the Home page.", comment: "after successfully downloading tendies"))
                    })
                }
            } catch {
                DispatchQueue.main.async {
                    Haptic.shared.notify(.error)
                    UIApplication.shared.dismissAlert(animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                        UIApplication.shared.alert(title: NSLocalizedString("Could not download wallpaper!", comment: ""), body: error.localizedDescription)
                    })
                }
            }
        }
    }
    
    func downloadFromURL(_ url: URL) async throws -> URL {
        print("Downloading from \(url.absoluteString)")
        
        let request = URLRequest(url: url)
            
        let (data, response) = try await URLSession.shared.data(for: request) as! (Data, HTTPURLResponse)
        guard response.statusCode == 200 else { throw URLError(.cannotConnectToHost) }
        let newURL = PosterBoardManager.shared.getTendiesStoreURL().appendingPathComponent(getWallpaperNameFromURL(string: url.absoluteString))
        try data.write(to: newURL)
        return newURL
    }
    
    func downloadFromURL(string path: String) async throws -> URL {
        guard let url = URL(string: path) else { throw URLError(.unknown) }
        return try await downloadFromURL(url)
    }
    
    func copyTendies(from url: URL) throws -> URL {
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
