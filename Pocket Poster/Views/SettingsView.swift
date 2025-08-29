//
//  SettingsView.swift
//  Pocket Poster
//
//  Created by lemin on 6/1/25.
//

import SwiftUI

struct SettingsView: View {
    // Prefs
    @AppStorage("pbHash") var pbHash: String = "" // PosterBoard hash
    @AppStorage("cpHash") var cpHash: String = "" // CarPlay hash
    @AppStorage("ignoreDurationLimit") var ignoreDurationLimit: Bool = false
    
    @State var checkingForHash: Bool = false
    @State var hashCheckTask: Task<Void, any Error>? = nil
    
    var body: some View {
        List {
            Section {
                VStack {
                    TextField("Enter PosterBoard App Hash", text: $pbHash)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                    if CarPlayManager.supportsCarPlay() {
                        TextField("Enter CarPlayWallpaper App Hash", text: $cpHash)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                    }
                    HStack {
                        Spacer()
                        // Run task to check until file exists from Nugget pc over AFC
                        Button(action: {
                            if !FileManager.default.fileExists(atPath: SymHandler.getPosterBoardHashURL().path()) {
                                // don't show the alert because it is already there
                                UIApplication.shared.confirmAlert(title: NSLocalizedString("Waiting for app hash...", comment: ""), body: NSLocalizedString("Connect your device to Nugget and click the \"Pocket Poster Helper\" button.", comment: ""), confirmTitle: NSLocalizedString("Cancel", comment: ""), onOK: {
                                    cancelWaitForHash()
                                }, noCancel: true)
                            }
                            startWaitForHash()
                        }) {
                            Text("Detect")
                        }
                        .foregroundStyle(.green)
                        .onChange(of: checkingForHash) { _ in
                            if !checkingForHash {
                                // hide ui alert
                                UIApplication.shared.dismissAlert(animated: true)
                            }
                        }
                    }
                }
            } header: {
                Label("App Hash", systemImage: "lock.app.dashed")
            }
            
            Section {
                Toggle(isOn: $ignoreDurationLimit, label: {
                    Label("Disable Video Duration Limit", systemImage: "ruler")
                })
            } header: {
                Label("Preferences", systemImage: "gear")
            }
            
            Section {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    UserDefaults.standard.set(false, forKey: "finishedTutorial")
                }) {
                    Label("Replay Tutorial", systemImage: "questionmark.circle")
                }
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    do {
                        try PosterBoardManager.clearCache()
                        Haptic.shared.notify(.success)
                        UIApplication.shared.alert(title: NSLocalizedString("App Cache Successfully Cleared!", comment: ""), body: "")
                    } catch {
                        Haptic.shared.notify(.error)
                        UIApplication.shared.alert(body: error.localizedDescription)
                    }
                }) {
                    Label("Clear App Cache", systemImage: "trash.circle")
                }
                .foregroundStyle(.red)
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    UserDefaults.standard.set(nil, forKey: "ActiveCarPlayWallpapers")
                    try? FileManager.default.removeItem(at: CarPlayManager.getCarPlayPhotosURL())
                    Haptic.shared.notify(.success)
                    UIApplication.shared.alert(title: NSLocalizedString("CarPlay Applied Wallpapers Successfully Cleared!", comment: ""), body: "")
                }) {
                    Label("Reset CarPlay Applied Wallpapers", systemImage: "trash.circle")
                }
                .foregroundStyle(.red)
            } header: {
                Label("Actions", systemImage: "gear")
            }
            
            // MARK: Links
            Section {
                if let scURL = URL(string: PosterBoardManager.ShortcutURL) {
                    Link(destination: scURL) {
                        Label("Download Fallback Shortcut", systemImage: "arrow.down.circle")
                    }
                }
                if let fbURL = URL(string: "shortcuts://run-shortcut?name=PosterBoard&input=text&text=troubleshoot") {
                    Link(destination: fbURL) {
                        Label("Create Additional Fallback Method", systemImage: "appclip")
                    }
                }
                if let nURL = URL(string: "https://github.com/leminlimez/Nugget") {
                    Link(destination: nURL) {
                        Label("Nugget GitHub", image: "github.fill")
                    }
                }
            } header: {
                Label("Links", systemImage: "link")
            }
            
            // MARK: Socials
            Section {
                Link(destination: URL(string: "https://github.com/leminlimez/Pocket-Poster")!) {
                    Label("View on GitHub", image: "github.fill")
                }
                Link(destination: URL(string: "https://discord.gg/MN8JgqSAqT")!) {
                    Label("Join the Discord", image: "discord.fill")
                }
                Link(destination: URL(string: "https://ko-fi.com/leminlimez")!) {
                    Label("Support on Ko-Fi", image: "ko-fi")
                }
            } header: {
                Label("Socials", systemImage: "globe")
            }
            
            // MARK: Credits
            Section {
                LinkCell(imageName: "leminlimez", url: "https://github.com/leminlimez", title: "LeminLimez", contribution: NSLocalizedString("Main Developer", comment: "leminlimez's contribution"), circle: true)
                LinkCell(imageName: "serstars", url: "https://github.com/SerStars", title: "SerStars", contribution: NSLocalizedString("Website Designer", comment: ""), circle: true)
                LinkCell(imageName: "Nathan", url: "https://github.com/verygenericname", title: "Nathan", contribution: NSLocalizedString("Exploit", comment: ""), circle: true)
                LinkCell(imageName: "duy", url: "https://github.com/khanhduytran0", title: "DuyKhanhTran", contribution: NSLocalizedString("Exploit", comment: ""), circle: true)
                LinkCell(imageName: "sky", url: "https://bsky.app/profile/did:plc:xykfeb7ieeo335g3aly6vev4", title: "dootskyre", contribution: NSLocalizedString("Fallback Shortcut Creator", comment: ""), circle: true)
                LinkCell(imageName: "POEditor", url: "https://poeditor.com/join/project/MPZOsunwVj", title: NSLocalizedString("Community Translators", comment: ""), contribution: "POEditor")
            } header: {
                Label("Credits", systemImage: "wrench.and.screwdriver")
            }
        }
    }
    
    func startWaitForHash() {
        checkingForHash = true
        hashCheckTask = Task {
            let filePath = SymHandler.getPosterBoardHashURL()
            while !FileManager.default.fileExists(atPath: filePath.path()) {
                try? await Task.sleep(nanoseconds: 500_000_000) // Sleep 0.5s
                try Task.checkCancellation()
            }
            
            do {
                let contents = try String(contentsOf: filePath)
                try? FileManager.default.removeItem(at: filePath)
                await MainActor.run {
                    pbHash = contents
                }
                // check for carplay hash
                if UIDevice.current.userInterfaceIdiom == .phone {
                    let carplayPath = SymHandler.getCarPlayHashURL()
                    if FileManager.default.fileExists(atPath: carplayPath.path()) {
                        let carplayContents = try String(contentsOf: carplayPath)
                        try? FileManager.default.removeItem(at: carplayPath)
                        await MainActor.run {
                            cpHash = carplayContents
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }

            await MainActor.run {
                checkingForHash = false
                hashCheckTask = nil
            }
        }
    }
    
    func cancelWaitForHash() {
        hashCheckTask?.cancel()
        hashCheckTask = nil
        checkingForHash = false
    }
}
