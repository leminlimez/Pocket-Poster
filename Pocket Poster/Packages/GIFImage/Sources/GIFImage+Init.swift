//
//  File.swift
//  
//
//  Created by Igor Ferreira on 06/04/2022.
//

import SwiftUI

public extension GIFImage {
    
    /// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
    /// into frames and stream them based in the "Delay" key packaged on which frame item.
    ///
    /// - Parameters:
    ///   - url: URL string of the image. If the string cannot be parsed into URL, this constructor early aborts and returns `nil`
    ///   - animate: A flag to indicate that GIF should animate or not. If non-animated, the first frame will be displayed
    ///   - loop: Flag to indicate if the GIF should be played only once or continue to loop
    ///   - placeholder: Image to be used before the source is loaded
    ///   - errorImage: If the stream fails, this image is used
    ///   - frameRate: Option to control the frame rate of the animation or to use the GIF information about frame rate
    ///   - loopAction: Closure called whenever the GIF finishes rendering one cycle of the action
    init?(
        url: String,
        animate: Bool,
        loop: Bool,
        placeholder: RawImage = RawImage(),
        errorImage: RawImage? = nil,
        frameRate: FrameRate = .dynamic,
        loopAction: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        self.init(
            url: url,
            animate: .constant(animate),
            loop: .constant(loop),
            placeholder: placeholder,
            errorImage: errorImage,
            frameRate: frameRate,
            loopAction: loopAction
        )
    }
    
    /// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
    /// into frames and stream them based in the "Delay" key packaged on which frame item.
    ///
    /// - Parameters:
    ///   - url: URL string of the image. If the string cannot be parsed into URL, this constructor early aborts and returns `nil`
    ///   - animate: A flag to indicate that GIF should animate or not. If non-animated, the first frame will be displayed
    ///   - loop: Flag to indicate if the GIF should be played only once or continue to loop
    ///   - placeholder: Image to be used before the source is loaded
    ///   - errorImage: If the stream fails, this image is used
    ///   - frameRate: Option to control the frame rate of the animation or to use the GIF information about frame rate
    ///   - loopAction: Closure called whenever the GIF finishes rendering one cycle of the action
    init?(
        url: String,
        animate: Binding<Bool> = Binding.constant(true),
        loop: Binding<Bool> = Binding.constant(true),
        placeholder: RawImage = RawImage(),
        errorImage: RawImage? = nil,
        frameRate: FrameRate = .dynamic,
        loopAction: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        guard let resolvedURL = URL(string: url) else {
            return nil
        }
        self.init(
            source: GIFSource.remoteURL(resolvedURL),
            animate: animate,
            loop: loop,
            placeholder: placeholder,
            errorImage: errorImage,
            frameRate: frameRate,
            loopAction: loopAction
        )
    }

    /// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
    /// into frames and stream them based in the "Delay" key packaged on which frame item.
    ///
    /// - Parameters:
    ///   - url: URL of the image. The response is cached using `URLCache`
    ///   - animate: A flag to indicate that GIF should animate or not. If non-animated, the first frame will be displayed
    ///   - loop: Flag to indicate if the GIF should be played only once or continue to loop
    ///   - placeholder: Image to be used before the source is loaded
    ///   - errorImage: If the stream fails, this image is used
    ///   - frameRate: Option to control the frame rate of the animation or to use the GIF information about frame rate
    ///   - loopAction: Closure called whenever the GIF finishes rendering one cycle of the action
    init(
        url: URL,
        animate: Bool = true,
        loop: Bool = true,
        placeholder: RawImage = RawImage(),
        errorImage: RawImage? = nil,
        frameRate: FrameRate = .dynamic,
        loopAction: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        self.init(
            url: url,
            animate: .constant(animate),
            loop: .constant(loop),
            placeholder: placeholder,
            errorImage: errorImage,
            frameRate: frameRate,
            loopAction: loopAction
        )
    }
    
    /// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
    /// into frames and stream them based in the "Delay" key packaged on which frame item.
    ///
    /// - Parameters:
    ///   - url: URL of the image. The response is cached using `URLCache`
    ///   - animate: A flag to indicate that GIF should animate or not. If non-animated, the first frame will be displayed
    ///   - loop: Flag to indicate if the GIF should be played only once or continue to loop
    ///   - placeholder: Image to be used before the source is loaded
    ///   - errorImage: If the stream fails, this image is used
    ///   - frameRate: Option to control the frame rate of the animation or to use the GIF information about frame rate
    ///   - loopAction: Closure called whenever the GIF finishes rendering one cycle of the action
    init(
        url: URL,
        animate: Binding<Bool> = Binding.constant(true),
        loop: Binding<Bool> = Binding.constant(true),
        placeholder: RawImage = RawImage(),
        errorImage: RawImage? = nil,
        frameRate: FrameRate = .dynamic,
        loopAction: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        self.init(
            source: GIFSource.remoteURL(url),
            animate: animate,
            loop: loop,
            placeholder: placeholder,
            errorImage: errorImage,
            frameRate: frameRate,
            loopAction: loopAction
        )
    }
    
    /// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
    /// into frames and stream them based in the "Delay" key packaged on which frame item.
    ///
    /// - Parameters:
    ///   - request: `URLRequest` of the image. The response is cached using `URLCache`
    ///   - animate: A flag to indicate that GIF should animate or not. If non-animated, the first frame will be displayed
    ///   - loop: Flag to indicate if the GIF should be played only once or continue to loop
    ///   - placeholder: Image to be used before the source is loaded
    ///   - errorImage: If the stream fails, this image is used
    ///   - frameRate: Option to control the frame rate of the animation or to use the GIF information about frame rate
    ///   - loopAction: Closure called whenever the GIF finishes rendering one cycle of the action
    init(
        request: URLRequest,
        animate: Binding<Bool> = Binding.constant(true),
        loop: Binding<Bool> = Binding.constant(true),
        placeholder: RawImage = RawImage(),
        errorImage: RawImage? = nil,
        frameRate: FrameRate = .dynamic,
        loopAction: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        self.init(
            source: GIFSource.remoteRequest(request),
            animate: animate,
            loop: loop,
            placeholder: placeholder,
            errorImage: errorImage,
            frameRate: frameRate,
            loopAction: loopAction
        )
    }
}
