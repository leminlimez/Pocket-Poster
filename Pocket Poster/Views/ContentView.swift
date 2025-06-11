//
//  ContentView.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie.mp4")

            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }

            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

struct ContentView: View {
    // Prefs
    @AppStorage("pbHash") var pbHash: String = ""
    
    @ObservedObject var pbManager = PosterBoardManager.shared
    
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    @State var showTendiesImporter: Bool = false
    
    enum LoadState {
        case unknown, loading, loaded(Movie), failed
    }
    @State var selectedVideo: PhotosPickerItem?
    @State private var loadState = LoadState.unknown
    
    @State var showErrorAlert = false
    @State var lastError: String?
    @State var hideResetHelp: Bool = true
    
    var body: some View {
        NavigationStack {
            List {
                Section {} header: {
                    Label("Version \(Bundle.main.releaseVersionNumber ?? "UNKNOWN") (\(Int(buildNumber) != 0 ? "Beta \(buildNumber)" : NSLocalizedString("Release", comment:"")))", systemImage: "info.circle.fill")
                        .font(.caption)
                }
                
                Section {
                    VStack {
                        switch loadState {
                        case .unknown:
                            EmptyView()
                        case .loading:
                            ProgressView()
                        case .loaded(let movie):
                            Text("Video imported")
                        case .failed:
                            Text("Import failed")
                        }
                        
                        switch loadState {
                        case .loaded(let movie):
                            Button(action: {
                                selectedVideo = nil
                                try? FileManager.default.removeItem(at: movie.url)
                                loadState = .unknown
                            }) {
                                Text("Remove Selected Video")
                            }
                            .buttonStyle(TintedButton(color: .red, fullwidth: true))
                        default:
                            PhotosPicker("Select Video", selection: $selectedVideo, matching: .videos)
                                .buttonStyle(TintedButton(color: .yellow, fullwidth: true))
                                .onChange(of: selectedVideo) { _ in
                                    Task {
                                        do {
                                            loadState = .loading
                                            
                                            if let movie = try await selectedVideo?.loadTransferable(type: Movie.self) {
                                                loadState = .loaded(movie)
                                            } else {
                                                loadState = .failed
                                            }
                                        } catch {
                                            loadState = .failed
                                        }
                                    }
                                }
                        }
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        showTendiesImporter.toggle()
                    }) {
                        Text("Select Tendies")
                    }
                    .buttonStyle(TintedButton(color: .green, fullwidth: true))
                }
                .listRowInsets(EdgeInsets())
                .padding(7)
                
                if !pbManager.selectedTendies.isEmpty {
                    Section {
                        ForEach(pbManager.selectedTendies, id: \.self) { tendie in
                            Text(tendie.deletingPathExtension().lastPathComponent)
                        }
                        .onDelete(perform: delete)
                    } header: {
                        Label("Selected Tendies", systemImage: "document")
                    }
                }
                
                Section {
                    if pbHash == "" {
                        Text("Enter your PosterBoard app hash in Settings.")
                    } else {
                        VStack {
                            if !pbManager.selectedTendies.isEmpty || selectedVideo != nil {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    UIApplication.shared.alert(title: NSLocalizedString("Applying Tendies...", comment: ""), body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        do {
                                            var videoURL: URL? = nil
                                            switch loadState {
                                            case .loaded(let movie):
                                                videoURL = movie.url
                                            default:
                                                videoURL = nil
                                            }
                                            try pbManager.applyTendies(appHash: pbHash, videoURL: videoURL)
                                            pbManager.selectedTendies.removeAll()
                                            SymHandler.cleanup() // just to be extra sure
                                            try? FileManager.default.removeItem(at: pbManager.getTendiesStoreURL())
                                            if let videoURL = videoURL {
                                                try? FileManager.default.removeItem(at: videoURL)
                                            }
                                            Haptic.shared.notify(.success)
                                            UIApplication.shared.dismissAlert(animated: true)
                                            UIApplication.shared.confirmAlert(title: "Success!", body: "The PosterBoard app will now open. Please close it from the app switcher.", onOK: {
                                                if !pbManager.openPosterBoard() {
                                                    UIApplication.shared.confirmAlert(title: "Falling Back to Shortcut", body: "PosterBoard failed to open directly. The fallback shortcut will now be opened.", onOK: {
                                                        pbManager.runShortcut(named: "PosterBoard")
                                                    }, noCancel: true)
                                                }
                                            }, noCancel: true)
                                        } catch {
                                            Haptic.shared.notify(.error)
                                            SymHandler.cleanup()
                                            UIApplication.shared.dismissAlert(animated: true)
                                            UIApplication.shared.alert(body: error.localizedDescription)
                                        }
                                    }
                                }) {
                                    Text("Apply")
                                }
                                .buttonStyle(TintedButton(color: .blue, fullwidth: true))
                            }
                            Button(action: {
                                guard let lang = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first else {
                                    hideResetHelp = false // fallback to tutorial
                                    return
                                }
                                UIApplication.shared.confirmAlert(title: "Reset Collections", body: "Do you want to reset collections?", onOK: {
                                    if pbManager.setSystemLanguage(to: lang) {
                                        UIApplication.shared.alert(title: "Collections Successfully Reset!", body: "Your PosterBoard will refresh automatically.")
                                    } else {
                                        UIApplication.shared.alert(body: "The API failed to call correctly.\nSystem Locale Code: \(lang)")
                                    }
                                }, noCancel: false)
                            }) {
                                Text("Reset Collections")
                            }
                            .buttonStyle(TintedButton(color: .red, fullwidth: true))
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(7)
                    }
                } header: {
                    Label("Actions", systemImage: "hammer")
                }
            }
            .navigationTitle("Pocket Poster")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let wpURL = URL(string: PosterBoardManager.WallpapersURL) {
                        Link(destination: wpURL) {
                            Image(systemName: "safari")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing, content: {
                    NavigationLink(destination: {
                        SettingsView()
                    }, label: {
                        Image(systemName: "gear")
                    })
                })
            }
        }
        .fileImporter(isPresented: $showTendiesImporter, allowedContentTypes: [UTType(filenameExtension: "tendies", conformingTo: .data)!], allowsMultipleSelection: true, onCompletion: { result in
            switch result {
            case .success(let url):
                if pbManager.selectedTendies.count + url.count > PosterBoardManager.MaxTendies {
                    UIApplication.shared.alert(title: "Max Tendies Reached", body: "You can only apply \(PosterBoardManager.MaxTendies) descriptors.")
                } else {
                    pbManager.selectedTendies.append(contentsOf: url)
                }
            case .failure(let error):
                lastError = error.localizedDescription
                showErrorAlert.toggle()
            }
        })
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(lastError ?? "???")
        }
        .overlay {
            OnBoardingView(cards: resetCollectionsInfo, isFinished: $hideResetHelp)
                .opacity(hideResetHelp ? 0.0 : 1.0)
                .transition(.opacity)
                .animation(.easeOut(duration: 0.5), value: hideResetHelp)
        }
    }
    
    func delete(at offsets: IndexSet) {
        pbManager.selectedTendies.remove(atOffsets: offsets)
    }
    
    init() {
        // Fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }
}
