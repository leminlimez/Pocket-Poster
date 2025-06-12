//
//  PlayerView.swift
//  Pocket Poster
//
//  Created by lemin on 6/11/25.
//

import SwiftUI

struct PlayerView: UIViewRepresentable {
    var videoURL: URL
    
    init(videoURL: URL) {
        self.videoURL = videoURL
    }
  
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
    }
  
    func makeUIView(context: Context) -> UIView {
        return LoopingPlayerUIView(videoURL: videoURL)
    }
}
