//
//  File.swift
//  
//
//  Created by Igor Ferreira on 05/04/2022.
//

import ImageIO
import SwiftUI
#if os(macOS)
import AppKit
public typealias RawImage = NSImage
#else
import UIKit
public typealias RawImage = UIImage
#endif

public extension RawImage {
    static func create(with cgImage: CGImage) -> RawImage {
        #if os(macOS)
        return RawImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #else
        return RawImage(cgImage: cgImage)
        #endif
    }

    static func create(symbol: String) -> RawImage? {
        #if os(macOS)
        return RawImage(systemSymbolName: symbol, accessibilityDescription: nil)
        #else
        return RawImage(systemName: symbol)
        #endif
    }
}

public extension Image {
    static func loadImage(with image: RawImage) -> Image {
        #if os(macOS)
        return Image(nsImage: image)
        #else
        return Image(uiImage: image)
        #endif
    }
}
