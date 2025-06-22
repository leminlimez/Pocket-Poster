//
//  CarPlayWallpaper.swift
//  Pocket Poster
//
//  Created by lemin on 6/22/25.
//

import SwiftUI

struct CarPlayWallpaper: Identifiable {
    var id = UUID()
    var name: String
    var lightImage: UIImage
    var darkImage: UIImage
    var selectedImageDataLight: Data?
    var selectedImageDataDark: Data?
    var changed: Bool
}

extension CarPlayWallpaper: Reorderable {
    typealias OrderElement = String
    var orderElement: OrderElement { name }
}
