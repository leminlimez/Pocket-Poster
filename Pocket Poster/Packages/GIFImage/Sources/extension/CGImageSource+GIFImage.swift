//
//  File.swift
//  
//
//  Created by Igor Ferreira on 05/04/2022.
//

import Foundation
import ImageIO

extension CGImageSource {
    func intervalAtIndex(_ index: Int) -> TimeInterval? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(self, index, nil) else {
            return nil
        }

        guard let gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary.asKey) else {
            return nil
        }

        let dictionary = unsafeBitCast(gifProperties, to: CFDictionary.self)

        let pointer: UnsafeRawPointer
        if let delay = CFDictionaryGetValue(dictionary, kCGImagePropertyGIFDelayTime.asKey) {
            pointer = delay
        } else if let unclampedDelay = CFDictionaryGetValue(dictionary, kCGImagePropertyGIFUnclampedDelayTime.asKey) {
            pointer = unclampedDelay
        } else {
            return nil
        }

        let interval = unsafeBitCast(pointer, to: AnyObject.self).doubleValue ?? 0.0
        if interval > 0.0 {
            return interval
        } else {
            return nil
        }
    }
}
