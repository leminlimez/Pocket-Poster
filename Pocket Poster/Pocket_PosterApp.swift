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
    @ObservedObject var dlManager = DownloadManager.shared
    
    @AppStorage("finishedTutorial") var finishedTutorial: Bool = false
    @AppStorage("pbHash") var pbHash: String = ""
    
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
            .onOpenURL(perform: { url in
                // Download URL
                if url.absoluteString.starts(with: "pocketposter://download") {
                    dlManager.startTendiesDownload(for: url)
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
                            let newURL = try DownloadManager.shared.copyTendies(from: url)
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
    
    init() {
        // clear the videos cache
        try? FileManager.default.removeItem(at: SymHandler.getDocumentsDirectory().appendingPathComponent("Videos", conformingTo: .directory))
    }
}
