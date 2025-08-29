//
//  CarPlayView.swift
//  Pocket Poster
//
//  Created by lemin on 6/19/25.
//

import SwiftUI
import PhotosUI

struct CarPlayView: View {
    @State var wallpapers: [CarPlayWallpaper] = []
    @State var didChange: Bool = false
    @State var showDark: Bool = false
    
    @AppStorage("cpHash") var cpHash: String = ""
    @State var activeWallpapers: [String] = []
    @ObservedObject var pbManager = PosterBoardManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    if wallpapers.isEmpty {
                        ProgressView()
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 250))]) {
                            ForEach($wallpapers) { wallpaper in
                                ZStack {
                                    WallpaperView(wallpaper: wallpaper, didChange: $didChange, showDark: $showDark)
                                        .disabled(activeWallpapers.contains(wallpaper.name.wrappedValue))
                                    // The checkmark
                                    if activeWallpapers.contains(wallpaper.name.wrappedValue) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .foregroundStyle(.black.opacity(0.4))
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                VStack {
                    Spacer()
                    if didChange {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            UIApplication.shared.alert(title: NSLocalizedString("Applying Wallpapers...", comment: ""), body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)

                            DispatchQueue.global(qos: .userInitiated).async {
                                do {
                                    try CarPlayManager.applyCarPlay(appHash: cpHash, wallpapers: wallpapers)
                                    SymHandler.cleanup() // just to be extra sure
                                    UIApplication.shared.dismissAlert(animated: false)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                                        activeWallpapers = UserDefaults.standard.array(forKey: "ActiveCarPlayWallpapers") as? [String] ?? []
                                        Haptic.shared.notify(.success)
                                        UIApplication.shared.alert(title: NSLocalizedString("Success!", comment: ""), body: NSLocalizedString("You can now choose your wallpapers in the CarPlay settings in your car.", comment: ""))
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
                            if cpHash == "" {
                                Text("Enter your CarPlayWallpaper app hash in Settings.")
                            } else {
                                Label("Apply CarPlay Wallpapers", systemImage: "checkmark.circle")
                            }
                        }
                        .buttonStyle(OpaqueButton(color: cpHash == "" ? .red : .blue, fullwidth: true))
                        .disabled(cpHash == "")
                        .padding(.vertical, 10)
                        .padding(.horizontal, 25)
                        .transition(.move(edge: .bottom))
                        .animation(.easeIn, value: didChange)
                    }
                }
            }
            .navigationTitle("CarPlay Wallpapers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing, content: {
                    Button(action: {
                        withAnimation {
                            showDark.toggle()
                        }
                    }) {
                        Image(systemName: showDark ? "moon" : "sun.max")
                    }
                })
            }
        }
        .onAppear {
            if wallpapers.isEmpty {
                // load active wallpapers from user defaults
                activeWallpapers = UserDefaults.standard.array(forKey: "ActiveCarPlayWallpapers") as? [String] ?? []
                // load the wallpapers
                let cppURL = CarPlayManager.getCarPlayPhotosURL()
                let frameworkPath = "/System/Library/PrivateFrameworks/CarPlayUIServices.framework"
                do {
                    for file in try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: frameworkPath), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                        if file.path().hasSuffix("-Light.heic") {
                            let imgData = try Data(contentsOf: file)
                            if let wpImg = UIImage(data: imgData) {
                                var darkImg = wpImg
                                if let darkData = try? Data(contentsOf: URL(fileURLWithPath: file.path().replacingOccurrences(of: "-Light.heic", with: "-Dark.heic"))) {
                                    darkImg = UIImage(data: darkData) ?? wpImg
                                }
                                let name = file.lastPathComponent.replacingOccurrences(of: "-Light.heic", with: "")
                                // fetch the selected image if they exist
                                let selectedLight: Data? = try? Data(contentsOf: cppURL.appendingPathComponent("\(name)-Light"))
                                let selectedDark: Data? = try? Data(contentsOf: cppURL.appendingPathComponent("\(name)-Dark"))
                                wallpapers.append(.init(
                                    name: name,
                                    lightImage: wpImg, darkImage: darkImg,
                                    selectedImageDataLight: selectedLight, selectedImageDataDark: selectedDark
                                ))
                            }
                        }
                    }
                    // sort them
                    if let sortedWallpapers = CarPlayManager.getCarPlayWallpaperNames() {
                        wallpapers = wallpapers.reorder(by: sortedWallpapers)
                    }
                } catch {
                    UIApplication.shared.alert(body: NSLocalizedString("Failed to fetch CarPlay wallpapers", comment: "") + ":\n\(error.localizedDescription)")
                }
            }
        }
    }
    
    func presentError(_ error: ApplyError) {
        SymHandler.cleanup()
        UIApplication.shared.dismissAlert(animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
            Haptic.shared.notify(.error)
            UIApplication.shared.alert(body: error.localizedDescription)
        })
    }
}

struct WallpaperView: View {
    @Binding var wallpaper: CarPlayWallpaper
    @Binding var didChange: Bool
    @Binding var showDark: Bool
    
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()) {
                VStack {
                    if showDark {
                        if let data = wallpaper.selectedImageDataDark, let img = UIImage(data: data) {
                            WallpaperImageView(img: img)
                        } else {
                            WallpaperImageView(img: wallpaper.darkImage)
                        }
                    } else {
                        if let data = wallpaper.selectedImageDataLight, let img = UIImage(data: data) {
                            WallpaperImageView(img: img)
                        } else {
                            WallpaperImageView(img: wallpaper.lightImage)
                        }
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray, lineWidth: 2)
            }
            .onChange(of: selectedItem) { newItem in
                if newItem == nil { return }
                Task {
                    // Retrieve selected asset in the form of Data
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if showDark {
                            wallpaper.selectedImageDataDark = data
                        } else {
                            wallpaper.selectedImageDataLight = data
                        }
                        selectedItem = nil
                        withAnimation {
                            didChange = true
                        }
                    }
                }
            }
    }
}

struct WallpaperImageView: View {
    var img: UIImage
    
    var body: some View {
        Image(uiImage: img)
            .resizable()
            .aspectRatio(1.35, contentMode: .fill)
            .cornerRadius(8)
            .clipped()
    }
}
