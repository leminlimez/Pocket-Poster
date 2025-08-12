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
}

extension CarPlayWallpaper: Reorderable {
    typealias OrderElement = String
    var orderElement: OrderElement { name }
}

class CarPlayManager {
    static func supportsCarPlay() -> Bool {
        if UIDevice.current.userInterfaceIdiom != .phone {
            // CarPlay is not on iPads
            return false
        }
        if #available(iOS 19, *) {
            // get the build number
            var osVersionString = [CChar](repeating: 0, count: 16)
            var osVersionStringLen = size_t(osVersionString.count - 1)

            let result = sysctlbyname("kern.osversion", &osVersionString, &osVersionStringLen, nil, 0)

            if result == 0 {
                // Convert C array to String
                if let build = String(validatingUTF8: osVersionString) {
                    // check build number for iOS 26 dev beta 1-3, return true if user is on that
                    if build == "23A5260n" // dev beta 1
                        || build == "23A5260u" // dev beta 1 (iPhone 15/16 series)
                        || build == "23A5276f" // dev beta 2
                        || build == "23A5287g" { // dev beta 3
                        return true
                    }
                } else {
                    print("Failed to convert build number to String")
                }
            } else {
                print("sysctlbyname failed with error: \(String(cString: strerror(errno)))")
            }
            return false
        }
        return true
    }
    
    static func getCarPlayCacheVersion() -> String {
        // they started adding numbers to the end in iOS 18, this is to compensate for that
        if #available(iOS 19.0, *) {
            return "-12"
        } else if #available(iOS 18.0, *) {
            return "-11"
        }
        return ""
    }
    
    static func getCarPlayWallpaperNames() -> [String]? {
        dlopen("/System/Library/PrivateFrameworks/CarPlayUIServices.framework/CarPlayUIServices", RTLD_GLOBAL)
        
        if #available(iOS 18.0, *) {
            // iOS 18 method (it got moved)
            guard let obj = objc_getClass("CRSUISystemWallpaper") as? NSObject else { print("no class"); return nil }
            
            if let success = obj.perform(Selector(("wallpapers"))), let arr = success.takeUnretainedValue() as? [NSObject] {
                var namesList: [String] = []
                for wp in arr {
                    if let wpACName = wp.perform(Selector(("wallpaperAssetCatalogName"))), let result = wpACName.takeUnretainedValue() as? String {
                        namesList.append(result)
                    }
                }
                return namesList
            }
        } else {
            // iOS 17-
            guard let obj = objc_getClass("CRSUIWallpaperPreferences") as? NSObject else { print("no class"); return nil }
            if let success = obj.perform(Selector(("availableWallpapers"))), let arr = success.takeUnretainedValue() as? [NSObject] {
                var namesList: [String] = []
                for wp in arr {
                    if let wpACName = wp.perform(Selector(("wallpaperAssetCatalogName"))), let result = wpACName.takeUnretainedValue() as? String {
                        namesList.append(result)
                    }
                }
                return namesList
            }
        }
        
        return nil
    }
    
    static func getCarPlayPhotosURL() -> URL {
        let cppURL = SymHandler.getDocumentsDirectory().appendingPathComponent("CarPlayPhotos", conformingTo: .directory)
        // create it if it doesn't exist
        if !FileManager.default.fileExists(atPath: cppURL.path()) {
            try? FileManager.default.createDirectory(at: cppURL, withIntermediateDirectories: true)
        }
        return cppURL
    }
    
    static func applyCarPlay(appHash: String, wallpapers: [CarPlayWallpaper]) throws {
        // write the image
        var toRemove: [URL] = []
        var activeWP: [String] = UserDefaults.standard.array(forKey: "ActiveCarPlayWallpapers") as? [String] ?? []
        let cppURL = getCarPlayPhotosURL()
        let cacheVer = getCarPlayCacheVersion()
        for wallpaper in wallpapers {
            if let data = wallpaper.selectedImageDataLight, let img = UIImage(data: data) {
                let imgURL = SymHandler.getDocumentsDirectory().appendingPathComponent("CAR\(wallpaper.name)Dynamic-Light\(cacheVer).cpbitmap")
                img.writeToCPBitmapFile(to: imgURL.path() as NSString)
                try? data.write(to: cppURL.appendingPathComponent("\(wallpaper.name)-Light"))
                toRemove.append(imgURL)
                if !activeWP.contains(wallpaper.name) {
                    activeWP.append(wallpaper.name)
                }
            }
            if let data = wallpaper.selectedImageDataDark, let img = UIImage(data: data) {
                let imgURL = SymHandler.getDocumentsDirectory().appendingPathComponent("CAR\(wallpaper.name)Dynamic-Dark\(cacheVer).cpbitmap")
                img.writeToCPBitmapFile(to: imgURL.path() as NSString)
                try? data.write(to: cppURL.appendingPathComponent("\(wallpaper.name)-Dark"))
                toRemove.append(imgURL)
                if !activeWP.contains(wallpaper.name) {
                    activeWP.append(wallpaper.name)
                }
            }
        }
        
        // symlink and apply
        let _ = try SymHandler.createAppSymlink(for: "\(appHash)/Library/Caches/MappedImageCache/com.apple.CarPlayApp.wallpaper-images")
        defer {
            SymHandler.cleanup()
        }
        for imgURL in toRemove {
            try FileManager.default.trashItem(at: imgURL, resultingItemURL: nil)
        }
        UserDefaults.standard.set(activeWP, forKey: "ActiveCarPlayWallpapers")
        let test = SymHandler.getDocumentsDirectory().appendingPathComponent("Caches")
        try Data(count: 0).write(to: test)
    }
}
