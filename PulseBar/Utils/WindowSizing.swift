//
//  WindowSizing.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import Foundation
import SwiftUI

enum WindowSizing {
    static let mainWindowWidth: CGFloat = 360
    static let mainWindowHeight: CGFloat = 680
    
    static let mainWindowSize = CGSize(width: mainWindowWidth, height: mainWindowHeight)
    
    // All views should use this consistent sizing
    static var viewFrame: some ViewModifier {
        ViewFrameModifier()
    }
}

struct ViewFrameModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: WindowSizing.mainWindowWidth, height: WindowSizing.mainWindowHeight)
    }
}

extension View {
    func standardWindowFrame() -> some View {
        self.modifier(ViewFrameModifier())
    }
}