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
    @State private var currentPage: Int = 0
    
    @State private var currentDate = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // update every second
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        if Locale.current.hourCycle == .zeroToEleven || Locale.current.hourCycle == .oneToTwelve {
            formatter.dateFormat = "h:mm"
        } else {
            formatter.dateFormat = "HH:mm"
        }
        return formatter
    }
    
    var body: some View {
        VStack {
            GeometryReader { geom in
                TabView(selection: $currentPage) {
                    ForEach(Array(pbManager.videos.enumerated()), id: \.offset) { idx, vid in
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
                                VStack {
                                    Text(dateFormatter.string(from: currentDate))
                                        .shadow(radius: 10)
                                    
                                    Text(timeFormatter.string(from: currentDate))
                                        .font(.system(size: 75, weight: .semibold, design: .rounded))
                                        .shadow(radius: 10)
                                    Spacer()
                                }
                                .padding(.top, 45)
                                .foregroundStyle(.white)
                            case .failed:
                                Text("Failed")
                            }
                        }
                        .frame(width: geom.size.width * 0.7, height: geom.size.height * 0.8)
                        .shadow(radius: 5)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(24)
                        .tag(idx)
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
                                pbManager.videos[idx].autoReverses = !vid.autoReverses
                            }) {
                                Image(systemName: "arrow.left.arrow.right.circle")
                                    .font(.title)
                                    .foregroundStyle(Color(uiColor: .label))
                                    .background {
                                        if vid.autoReverses {
                                            Circle()
                                                .foregroundStyle(.blue.opacity(0.8))
                                                .shadow(radius: 5)
                                        } else {
                                            Circle()
                                                .foregroundStyle(.regularMaterial)
                                                .shadow(radius: 5)
                                        }
                                    }
                            }.offset(x: 8, y: -8),
                            alignment: .topTrailing
                        )
                    }
                    .onDelete(perform: removeVideo)
                    .onReceive(timer) { input in
                        currentDate = input
                    }
                    
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
                        .tag(pbManager.videos.count)
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
                                        currentPage = id
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
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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
                            .foregroundStyle(.regularMaterial)
                            .shadow(radius: 5)
                    }
            }
            .offset(x: -8, y: -8)
        }
    }
}
