//
//  File.swift
//  
//
//  Created by Igor Ferreira on 05/04/2022.
//

import Foundation
import ImageIO

extension Data {
    func imageAsyncSequence() throws -> CGImageSourceFrameSequence {
        return try CGImageSourceFrameSequence(data: self)
    }
}
