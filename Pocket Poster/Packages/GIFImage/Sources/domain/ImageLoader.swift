//
//  File.swift
//  
//
//  Created by Igor Ferreira on 05/04/2022.
//

import Foundation

/// Object responsible to load a `GIFSource` into a `ImageFrame` stream.
public struct ImageLoader {
    public let session: URLSession
    public let cache: URLCache
    public let fileManager: FileManager

    public init(session: URLSession = .shared, cache: URLCache = .shared, fileManager: FileManager = .default) {
        self.session = session
        self.cache = cache
        self.fileManager = fileManager
    }

    public func load(source: GIFSource) async throws -> CGImageSourceFrameSequence {
        let data = try await source.loadData(session: session, cache: cache, fileManager: fileManager)
        return try data.imageAsyncSequence()
    }
}

private extension GIFSource {
    func loadData(session: URLSession, cache: URLCache, fileManager: FileManager) async throws -> Data {
        switch self {
        case let .static(data): data
        case .remote(let url), .remoteURL(let url): try await url.loadData(session: session, cache: cache)
        case let .remoteRequest(request): try await request.loadData(session: session, cache: cache)
        case let .local(filePath): try await filePath.loadData(fileManager: fileManager)
        }
    }
}

private extension String {
    func loadData(fileManager: FileManager) async throws -> Data {
        guard fileManager.fileExists(atPath: self) else {
            throw URLError(.fileDoesNotExist)
        }
        guard let data = fileManager.contents(atPath: self) else {
            throw URLError(.cannotOpenFile)
        }
        return data
    }
}

private extension URL {
    func loadData(session: URLSession, cache: URLCache) async throws -> Data {
        let request = URLRequest(url: self)
        return try await request.loadData(session: session, cache: cache)
    }
}

private extension URLRequest {
    func loadData(session: URLSession, cache: URLCache) async throws -> Data {
        if let cache = cache.cachedResponse(for: self) {
            return cache.data
        }

        let (data, response) = try await session.data(for: self)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard httpResponse.isSuccess else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: self)
        return data
    }
}

private extension HTTPURLResponse {
    var isSuccess: Bool {
        200..<300 ~= statusCode
    }
}
