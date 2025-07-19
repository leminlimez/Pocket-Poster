//
//  File.swift
//  
//
//  Created by Igor Ferreira on 05/04/2022.
//

import Foundation
import ImageIO

public actor CGImageSourceIterator: AsyncIteratorProtocol {

    public let frameCount: Int
    public let source: CGImageSource
    public private(set) var currentFrame: Int

    public init(source: CGImageSource) {
        self.source = source
        self.frameCount = CGImageSourceGetCount(source)
        self.currentFrame = 0
    }

    public func next() async throws -> ImageFrame? {
        guard currentFrame < frameCount else {
            return nil
        }

        let frame: ImageFrame? = if let image = CGImageSourceCreateImageAtIndex(source, currentFrame, nil) {
            ImageFrame(image: image, interval: source.intervalAtIndex(currentFrame))
        } else {
            nil
        }
        currentFrame += 1
        return frame
    }
}
