//
//  VideoView.swift
//  Pocket Poster
//
//  Created by lemin on 6/11/25.
//

import SwiftUI
import PhotosUI
import AVKit

struct VideoView: View {
    @ObservedObject var pbManager = PosterBoardManager.shared
    @AppStorage("ignoreDurationLimit") var ignoreDurationLimit: Bool = false
    
    @State var selectedVideo: PhotosPickerItem?
    
    var body: some View {
        VStack {
            GeometryReader { geom in
                TabView {
                    ForEach(pbManager.videos) { vid in
                        ZStack {
                            switch vid.loadState {
                            case .unknown:
                                EmptyView()
                            case .loading:
                                ProgressView()
                            case .loaded(let movie):
                                PlayerView(videoURL: movie.url)
                                    .scaledToFill()
                                    .frame(width: geom.size.width * 0.7, height: geom.size.height * 0.8)
                                    .clipped()
                            case .failed:
                                Text("Failed")
                            }
                        }
                        .frame(width: geom.size.width * 0.7, height: geom.size.height * 0.8)
                        .shadow(radius: 5)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(24)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.gray, lineWidth: 4)
                        }
                        .overlay(
                            // Delete Button
                            DeleteButton(video: vid, onDelete: removeVideo),
                            alignment: .topLeading
                        )
                        .overlay(
                            // Loops Button
                            Button(action: {
                                if let index = pbManager.videos.firstIndex(of: vid) {
                                    pbManager.videos[index].autoReverses = !vid.autoReverses
                                }
                            }) {
                                Image(systemName: "arrow.left.arrow.right.circle")
                                    .font(.title)
                                    .foregroundStyle(.black)
                                    .background {
                                        Circle()
                                            .foregroundStyle(vid.autoReverses ? .blue : .white)
                                    }
                            }.offset(x: 8, y: -8),
                            alignment: .topTrailing
                        )
                    }
                    .onDelete(perform: removeVideo)
                    
                    // MARK: Select Photo Option
                    if selectedVideo == nil && pbManager.videos.count < 5 {
                        ZStack {
                            PhotosPicker(selection: $selectedVideo, matching: .videos, label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(.gray.opacity(0.4))
                                    
                                    Circle()
                                        .frame(width: 40, height: 40)
                                        .foregroundStyle(.blue)
                                    
                                    Image(systemName: "plus")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                            })
                        }
                        .frame(width: geom.size.width * 0.7, height: geom.size.height * 0.8)
                        .shadow(radius: 5)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(24)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.gray, lineWidth: 4)
                        }
                    }
                }
                .onChange(of: selectedVideo) { _ in
                    if selectedVideo == nil { return }
                    let id = pbManager.videos.count
                    pbManager.videos.append(.init(loadState: .loading))
                    Task {
                        do {
                            if let movie = try await selectedVideo?.loadTransferable(type: Movie.self) {
                                await MainActor.run {
                                    if !ignoreDurationLimit && VideoHandler.isVideoTooLong(at: movie.url) {
                                        pbManager.videos.remove(at: id)
                                        UIApplication.shared.alert(title: NSLocalizedString("Failed to Import Video", comment: ""), body: String(format: NSLocalizedString("The video you imported is too long! Your video must be %@ seconds or less.", comment: ""), "\(Int(VideoHandler.MaxDurationSecs))"))
                                    } else {
                                        pbManager.videos[id].loadState = .loaded(movie)
                                    }
                                }
                            } else {
                                await MainActor.run {
                                    pbManager.videos[id].loadState = .failed
                                }
                            }
                        } catch {
                            await MainActor.run {
                                pbManager.videos[id].loadState = .failed
                            }
                        }
                        selectedVideo = nil
                    }
                }
                .tabViewStyle(.page)
            }
        }
    }
    
    func removeVideo(at offsets: IndexSet) {
        withAnimation {
            pbManager.videos.remove(atOffsets: offsets)
        }
    }
}

struct DeleteButton: View {
    @Environment(\.editMode) var editMode

    let video: LoadInfo
    @ObservedObject var pbManager = PosterBoardManager.shared
    let onDelete: (IndexSet) -> ()

    var body: some View {
        VStack {
            Button(action: {
                if let index = pbManager.videos.firstIndex(of: video) {
                    self.onDelete(IndexSet(integer: index))
                }
            }) {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.red)
                    .font(.title)
                    .background {
                        Circle()
                            .foregroundStyle(.white)
                    }
            }
            .offset(x: -8, y: -8)
        }
    }
}
