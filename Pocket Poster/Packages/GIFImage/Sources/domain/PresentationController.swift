//
//  File.swift
//  
//
//  Created by Igor Ferreira on 9/9/22.
//

import Foundation
import SwiftUI

private let kDefaultGIFFrameInterval: TimeInterval = 1.0 / 24.0

struct PresentationController {
    let source: GIFSource
    let frameRate: FrameRate
    let action: (GIFSource) async throws -> Void
    @Binding var animate: Bool
    @Binding var loop: Bool
    
    init(
        source: GIFSource,
        frameRate: FrameRate,
        animate: Binding<Bool>,
        loop: Binding<Bool>,
        action: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        self.source = source
        self.action = action
        self.frameRate = frameRate
        self._animate = animate
        self._loop = loop
    }
    
    func start(imageLoader: ImageLoader, fallbackImage: RawImage, frameUpdate: (RawImage) async -> Void) async {
        do {
            repeat {
                for try await imageFrame in try await imageLoader.load(source: source) {
                    try await update(imageFrame, frameUpdate: frameUpdate)
                    if !animate { break }
                }
                try await action(source)
            } while(self.loop && self.animate)
        } catch {
            if !(error is CancellationError) {
                await frameUpdate(fallbackImage)
            }
        }
    }
    
    private func update(_ imageFrame: ImageFrame, frameUpdate: (RawImage) async -> Void) async throws {
        await frameUpdate(RawImage.create(with: imageFrame.image))
        let calculatedInterval = imageFrame.interval ?? kDefaultGIFFrameInterval
        let interval: Double
        switch frameRate {
        case .static(let fps):
            interval = (1.0 / Double(fps))
        case .limited(let fps):
            let intervalLimit = (1.0 / Double(fps))
            interval = max(calculatedInterval, intervalLimit)
        case .dynamic:
            interval = imageFrame.interval ?? kDefaultGIFFrameInterval
        }
        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000.0))
    }
}
