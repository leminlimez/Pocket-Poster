//
//  LoopingPlayerUIView.swift
//  Pocket Poster
//
//  Created by lemin on 6/11/25.
//

import UIKit
import AVFoundation

class LoopingPlayerUIView: UIView {
  
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    private var player = AVQueuePlayer()
  
    init(videoURL: URL){
        let asset = AVAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)

        super.init(frame: .zero)
        
        // Setup the player
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)

        // Create a new player looper with the queue player and template item
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        player.play()
    }
       
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
