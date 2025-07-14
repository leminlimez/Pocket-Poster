//
//  SymHandler.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import Foundation

class SymHandler {
    // MARK: URL Getter Operations
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    static func getLCDocumentsDirectory() -> URL {
        let lcPath = ProcessInfo.processInfo.environment["LC_HOME_PATH"]
        if let lcPath = lcPath {
            return URL(fileURLWithPath: "\(lcPath)/Documents")
        }
        return getDocumentsDirectory()
    }
    
    static func getPosterBoardHashURL() -> URL {
        return getLCDocumentsDirectory().appendingPathComponent("NuggetPosterBoardHash")
    }
    static func getCarPlayHashURL() -> URL {
        return getLCDocumentsDirectory().appendingPathComponent("NuggetCarPlayWallpaperHash")
    }
    
    private static func getSymlinkURL() -> URL {
        return getLCDocumentsDirectory().appendingPathComponent(".Trash", conformingTo: .symbolicLink)
    }
    
    // MARK: Symlink Creation
    static func createSymlink(to path: String) throws -> URL {
        // returns the url of the symlink
        let symURL = getSymlinkURL()
        cleanup()
        
        // create the symlink to the hashed app folder
        try FileManager.default.createSymbolicLink(at: symURL, withDestinationURL: URL(fileURLWithPath: path, isDirectory: true))
        
        return symURL
    }
    
    static func createAppSymlink(for appHash: String) throws -> URL {
        return try createSymlink(to: "/var/mobile/Containers/Data/Application/\(appHash)")
    }
    
    static func getExtensionVersion() -> String {
        if #available(iOS 17.0, *) {
            return "61"
        }
        return "59"
    }
    
    static func createDescriptorsSymlink(appHash: String, ext: String) throws -> URL {
        // create a symlink directly to the descriptors
        let extVer = SymHandler.getExtensionVersion()
        print("linking to \(appHash)/Library/Application Support/PRBPosterExtensionDataStore/\(extVer)/Extensions/\(ext)/descriptors")
        return try createAppSymlink(for: "\(appHash)/Library/Application Support/PRBPosterExtensionDataStore/\(extVer)/Extensions/\(ext)/descriptors")
    }
    
    static func cleanup() {
        // remove the symlink if it exists
        let symURL = getSymlinkURL()
        // remove existing symlink
        try? FileManager.default.removeItem(at: symURL)
    }
}
