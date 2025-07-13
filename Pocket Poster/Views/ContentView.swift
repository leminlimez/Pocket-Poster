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

struct ContentView: View {
    // Prefs
    @AppStorage("pbHash") var pbHash: String = ""
    
    @ObservedObject var pbManager = PosterBoardManager.shared
    
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    @State var showTendiesImporter: Bool = false
    @State var hideResetHelp: Bool = true
    
    var body: some View {
        NavigationStack {
            List {
                Section {} header: {
                    Label("Version \(Bundle.main.releaseVersionNumber ?? "UNKNOWN") (\(Int(buildNumber) != 0 ? "Beta \(buildNumber)" : NSLocalizedString("Release", comment:"")))", systemImage: "info.circle.fill")
                        .font(.caption)
                }
                
                Section {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        showTendiesImporter.toggle()
                    }) {
                        Label("Select Tendies", systemImage: "document.circle")
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
                            if !pbManager.selectedTendies.isEmpty || !pbManager.videos.isEmpty {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    UIApplication.shared.alert(title: NSLocalizedString("Applying Wallpapers...", comment: ""), body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)

                                    DispatchQueue.global(qos: .userInitiated).async {
                                        do {
                                            try pbManager.applyTendies(appHash: pbHash)
                                            SymHandler.cleanup() // just to be extra sure
                                            try? FileManager.default.removeItem(at: pbManager.getTendiesStoreURL())
                                            UIApplication.shared.dismissAlert(animated: false)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                                                pbManager.selectedTendies.removeAll()
                                                Haptic.shared.notify(.success)
                                                UIApplication.shared.confirmAlert(title: NSLocalizedString("Success!", comment: ""), body: NSLocalizedString("The PosterBoard app will now open. Please close it from the app switcher.", comment: ""), onOK: {
                                                    if !pbManager.openPosterBoard() {
                                                        UIApplication.shared.confirmAlert(title: NSLocalizedString("Falling Back to Shortcut", comment: ""), body: NSLocalizedString("PosterBoard failed to open directly. The fallback shortcut will now be opened.", comment: ""), onOK: {
                                                            pbManager.runShortcut(named: "PosterBoard")
                                                        }, noCancel: true)
                                                    }
                                                }, noCancel: true)
                                            })
                                        } catch CocoaError.fileWriteUnknown {
                                            presentError(ApplyError.wrongAppHash)
                                        } catch CocoaError.fileWriteFileExists {
                                            presentError(ApplyError.collectionsNeedsReset)
                                        } catch {
                                            print(error.localizedDescription)
                                            presentError(ApplyError.unexpected(info: error.localizedDescription))
                                        }
                                    }
                                }) {
                                    Label("Apply", systemImage: "checkmark.circle")
                                }
                                .buttonStyle(TintedButton(color: .blue, fullwidth: true))
                            }
                            Button(action: {
                                if #available(iOS 18.0, *) {
                                    guard let lang = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first else {
                                        hideResetHelp = false // fallback to tutorial
                                        return
                                    }
                                    UIApplication.shared.confirmAlert(title: NSLocalizedString("Reset Collections", comment: ""), body: NSLocalizedString("Do you want to reset collections?", comment: ""), onOK: {
                                        if pbManager.setSystemLanguage(to: lang) {
                                            UIApplication.shared.alert(title: NSLocalizedString("Collections Successfully Reset!", comment: ""), body: NSLocalizedString("Your PosterBoard will refresh automatically.", comment: ""))
                                        } else {
                                            UIApplication.shared.alert(body: "The API failed to call correctly.\nSystem Locale Code: \(lang)")
                                        }
                                    }, noCancel: false)
                                } else {
                                    hideResetHelp = false
                                }
                            }) {
                                Label("Reset Collections", systemImage: "arrow.clockwise.circle")
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
                    UIApplication.shared.alert(title: NSLocalizedString("Max Tendies Reached", comment: ""), body: String(format: NSLocalizedString("You can only apply %@ descriptors.", comment: ""), "\(PosterBoardManager.MaxTendies)"))
                } else {
                    pbManager.selectedTendies.append(contentsOf: url)
                }
            case .failure(let error):
                Haptic.shared.notify(.error)
                UIApplication.shared.alert(body: error.localizedDescription)
            }
        })
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
    
    func presentError(_ error: ApplyError) {
        SymHandler.cleanup()
        UIApplication.shared.dismissAlert(animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
            Haptic.shared.notify(.error)
            UIApplication.shared.alert(body: error.localizedDescription)
        })
    }
    
    init() {
        // Fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }
}
