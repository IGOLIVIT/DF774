//
//  AppColors.swift
//  DF774
//

import SwiftUI

// MARK: - App Colors Extension
// Using Color(_:) initializer for compatibility with all Xcode versions
extension Color {
    static let appDarkSurface = Color("DarkSurface")
    static let appDeepCharcoal = Color("DeepCharcoal")
    static let appMutedAmber = Color("MutedAmber")
    static let appSoftCream = Color("SoftCream")
    static let appSuccessGreen = Color("SuccessGreen")
    static let appWarmGold = Color("WarmGold")
}

// MARK: - ShapeStyle Convenience
extension ShapeStyle where Self == Color {
    static var appDarkSurface: Color { Color("DarkSurface") }
    static var appDeepCharcoal: Color { Color("DeepCharcoal") }
    static var appMutedAmber: Color { Color("MutedAmber") }
    static var appSoftCream: Color { Color("SoftCream") }
    static var appSuccessGreen: Color { Color("SuccessGreen") }
    static var appWarmGold: Color { Color("WarmGold") }
}

