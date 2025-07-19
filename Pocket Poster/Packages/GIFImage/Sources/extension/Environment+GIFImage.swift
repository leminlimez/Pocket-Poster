//
//  File.swift
//  
//
//  Created by Igor Ferreira on 05/04/2022.
//

import SwiftUI

struct GIFImageEnvironment: EnvironmentKey {
    static var defaultValue: ImageLoader = {
        return ImageLoader()
    }()
}

extension EnvironmentValues {
    var imageLoader: ImageLoader {
        get { self[GIFImageEnvironment.self] }
        set { self[GIFImageEnvironment.self] = newValue }
    }
}

extension View {
    @ViewBuilder
    func with(imageLoader: ImageLoader) -> some View {
        environment(\.imageLoader, imageLoader)
    }
}
