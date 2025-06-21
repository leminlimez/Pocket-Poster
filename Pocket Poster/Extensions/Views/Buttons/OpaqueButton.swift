//
//  OpaqueButton.swift
//  Pocket Poster
//
//  Created by lemin on 6/21/25.
//

import SwiftUI

struct OpaqueButton: ButtonStyle {
    var color: Color
    var textColor: Color
    var fullwidth: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if fullwidth {
                configuration.label
                    .padding(15)
                    .frame(maxWidth: .infinity)
                    .background(color)
                    .cornerRadius(8)
                    .foregroundColor(textColor)
            } else {
                configuration.label
                    .padding(15)
                    .background(color)
                    .cornerRadius(8)
                    .foregroundColor(textColor)
            }
        }
    }
    
    init(color: Color = .blue, textColor: Color = .primary, fullwidth: Bool = false) {
        self.color = color
        self.textColor = textColor
        self.fullwidth = fullwidth
    }
}
