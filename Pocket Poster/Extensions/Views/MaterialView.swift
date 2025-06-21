//
//  MaterialView.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import SwiftUI

struct MaterialView: UIViewRepresentable {
    let material: UIBlurEffect.Style

    init(_ material: UIBlurEffect.Style) {
        self.material = material
    }

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: material))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: material)
    }
}
