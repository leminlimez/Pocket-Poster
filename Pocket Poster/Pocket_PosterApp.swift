//
//  Pocket_PosterApp.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import SwiftUI

@main
struct Pocket_PosterApp: App {
    // Prefs
    @AppStorage("finishedTutorial") var finishedTutorial: Bool = false
    @AppStorage("pbHash") var pbHash: String = ""
    
    @State var downloadURL: String? = nil
    @State var showDownloadAlert = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if finishedTutorial {
                    RootView()
                } else {
                    OnBoardingView(cards: onBoardingCards, isFinished: $finishedTutorial)
                }
            }
            .transition(.opacity)
            .animation(.easeOut(duration: 0.5), value: finishedTutorial)
            .alert("Download Tendies File", isPresented: $showDownloadAlert) {
                Button("OK") {
                    downloadWallpaper()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Would you like to download the file \(DownloadManager.getWallpaperNameFromURL(string: downloadURL ?? "/Unknown"))?")
            }
            .onOpenURL(perform: { url in
                // Download URL
                if url.absoluteString.starts(with: "pocketposter://download") {
                    // prohibit to only tendies files
                    if !url.absoluteString.hasSuffix(".tendies") {
                        UIApplication.shared.alert(body: "Only .tendies files can be downloaded!")
                    } else if PosterBoardManager.shared.selectedTendies.count >= PosterBoardManager.MaxTendies {
                        UIApplication.shared.alert(title: "Max Tendies Reached", body: "You can only apply \(PosterBoardManager.MaxTendies) descriptors.")
                    } else {
                        downloadURL = url.absoluteString.replacingOccurrences(of: "pocketposter://download?url=", with: "")
                        showDownloadAlert = true
                    }
                }
                // App Hash URL
                else if url.absoluteString.starts(with: "pocketposter://app-hash?uuid=") {
                    pbHash = url.absoluteString.replacingOccurrences(of: "pocketposter://app-hash?uuid=", with: "")
                }
                else if url.pathExtension == "tendies" {
                    if PosterBoardManager.shared.selectedTendies.count >= PosterBoardManager.MaxTendies {
                        UIApplication.shared.alert(title: "Max Tendies Reached", body: "You can only apply \(PosterBoardManager.MaxTendies) descriptors.")
                    } else {
                        // copy it over to the KFC bucket
                        do {
                            let newURL = try DownloadManager.copyTendies(from: url)
                            PosterBoardManager.shared.selectedTendies.append(newURL)
                            Haptic.shared.notify(.success)
                            UIApplication.shared.alert(title: "Successfully imported \(url.lastPathComponent)", body: "")
                        } catch {
                            Haptic.shared.notify(.error)
                            UIApplication.shared.alert(title: "Failed to import tendies", body: error.localizedDescription)
                        }
                    }
                }
            })
        }
    }
    
    func downloadWallpaper() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        UIApplication.shared.alert(title: NSLocalizedString("Downloading", comment: "") + " \(DownloadManager.getWallpaperNameFromURL(string: downloadURL ?? "/Unknown"))...", body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)
        
        Task {
            do {
                let newURL = try await DownloadManager.downloadFromURL(string: downloadURL!)
                PosterBoardManager.shared.selectedTendies.append(newURL)
                Haptic.shared.notify(.success)
                UIApplication.shared.dismissAlert(animated: true)
            } catch {
                Haptic.shared.notify(.error)
                UIApplication.shared.dismissAlert(animated: true)
                UIApplication.shared.alert(title: NSLocalizedString("Could not download wallpaper!", comment: ""), body: error.localizedDescription)
            }
        }
    }
}
