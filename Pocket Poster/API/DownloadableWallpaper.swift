//
//  DownloadableWallpaper.swift
//  Pocket Poster
//
//  Created by lemin on 7/15/25.
//

class DownloadableWallpaper: Identifiable, Codable {
    var name: String
    var description: String?
    var url: String
    var preview: String
    var authors: String?
    var type: WallpaperType?

    init(name: String, description: String?, authors: String?, preview: String, url: String, version: String) {
        self.name = name
        self.description = description
        self.authors = authors
        self.preview = preview
        self.url = url
    }
    
    enum WallpaperType: String, Codable {
        case custom, apple, template
    }
    
    func previewIsGif() -> Bool {
        return preview.hasSuffix(".gif")
    }
}
