//
//  CPBitmapHandler.swift
//  Pocket Poster
//
//  Created by lemin on 6/16/25.
//

import UIKit
import Dynamic

class CPBitmapHandler {
    static func resizeAndSave(image: UIImage, to url: URL, size: CGSize) throws {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        try? FileManager.default.removeItem(at: url)

        resizedImage.writeToCPBitmapFile(to: url.path() as NSString)
    }
}

extension UIImage {
    func writeToCPBitmapFile(to path: NSString) {
        Dynamic(self).writeToCPBitmapFile(path, flags: 1)
    }
}
