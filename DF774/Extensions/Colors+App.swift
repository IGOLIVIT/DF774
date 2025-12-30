//
//  Colors+App.swift
//  DF774
//

import SwiftUI

extension Color {
    // Primary colors
    static let warmGold = Color("WarmGold")
    static let mutedAmber = Color("MutedAmber")
    static let successGreen = Color("SuccessGreen")
    
    // Background colors
    static let deepCharcoal = Color("DeepCharcoal")
    static let darkSurface = Color("DarkSurface")
    
    // Text colors
    static let softCream = Color("SoftCream")
}

// MARK: - Fallback colors (if asset catalog colors not found)
extension Color {
    static func safeColor(_ name: String, fallback: Color) -> Color {
        if UIColor(named: name) != nil {
            return Color(name)
        }
        return fallback
    }
}

