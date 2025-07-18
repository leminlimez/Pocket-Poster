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
    @State var checkedForUpdate: Bool = false
    
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
            .onAppear {
                // check for update
                if !checkedForUpdate {
                    checkedForUpdate = true
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let url = URL(string: "https://api.github.com/leminlimez/Pocket-Poster/releases/latest") {
                        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                            guard let data = data else { return }
                            
                            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                                if (json["tag_name"] as? String)?.replacingOccurrences(of: "v", with: "").compare(version, options: .numeric) == .orderedDescending {
                                    UIApplication.shared.confirmAlert(
                                        title: NSLocalizedString("Update Available", comment: "app update available on GitHub"),
                                        body: String(format: NSLocalizedString("Pocket Poster %@ is available, do you want to visit releases page?", comment: "app update available on GitHub"), json["tag_name"] as? String ?? "update"),
                                        onOK: {
                                        UIApplication.shared.open(URL(string: "https://github.com/leminlimez/Pocket-Poster/releases/latest")!)
                                    }, noCancel: false)
                                }
                            }
                        }
                        task.resume()
                    }
                }
            }
            .onOpenURL(perform: { url in
                // Download URL
                if url.absoluteString.starts(with: "pocketposter://download") {
                    // prohibit to only tendies files
                    if !url.absoluteString.hasSuffix(".tendies") {
                        UIApplication.shared.alert(body: NSLocalizedString("Only .tendies files can be downloaded!", comment: ""))
                    } else if PosterBoardManager.shared.selectedTendies.count >= PosterBoardManager.MaxTendies {
                        UIApplication.shared.alert(title: NSLocalizedString("Max Tendies Reached", comment: ""), body: String(format: NSLocalizedString("You can only apply %@ descriptors.", comment: ""), "\(PosterBoardManager.MaxTendies)"))
                    } else {
                        downloadURL = url.absoluteString.replacingOccurrences(of: "pocketposter://download?url=", with: "")
                        UIApplication.shared.confirmAlert(title: NSLocalizedString("Download Tendies File", comment: ""), body: String(format: NSLocalizedString("Would you like to download the file %@?", comment: ""), "\(DownloadManager.getWallpaperNameFromURL(string: downloadURL ?? "/Unknown"))"), onOK: {
                            downloadWallpaper()
                        }, noCancel: false)
                    }
                }
                // App Hash URL
                else if url.absoluteString.starts(with: "pocketposter://app-hash?uuid=") {
                    pbHash = url.absoluteString.replacingOccurrences(of: "pocketposter://app-hash?uuid=", with: "")
                }
                else if url.pathExtension == "tendies" {
                    if PosterBoardManager.shared.selectedTendies.count >= PosterBoardManager.MaxTendies {
                        UIApplication.shared.alert(title: NSLocalizedString("Max Tendies Reached", comment: ""), body: String(format: NSLocalizedString("You can only apply %@ descriptors.", comment: ""), "\(PosterBoardManager.MaxTendies)"))
                    } else {
                        // copy it over to the KFC bucket
                        do {
                            let newURL = try DownloadManager.copyTendies(from: url)
                            PosterBoardManager.shared.selectedTendies.append(newURL)
                            Haptic.shared.notify(.success)
                            UIApplication.shared.alert(title: String(format: NSLocalizedString("Successfully imported %@", comment: ""), "\(url.lastPathComponent)"), body: "")
                        } catch {
                            Haptic.shared.notify(.error)
                            UIApplication.shared.alert(title: NSLocalizedString("Failed to import tendies", comment: ""), body: error.localizedDescription)
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
    
    init() {
        // clear the videos cache
        try? FileManager.default.removeItem(at: SymHandler.getDocumentsDirectory().appendingPathComponent("Videos", conformingTo: .directory))
    }
}
