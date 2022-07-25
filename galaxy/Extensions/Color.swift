//
//  Color.swift
//  galaxy
//
//  Created by pkulik0 on 19/07/2022.
//

import SwiftUI

extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
    
    static let fallbackColors: [Color] = [.yellow, .blue, .orange, .green, .red, .cyan, .brown, .indigo, .pink, .mint]
    
    static func fromHexString(hex: String, nickname: String, opacity: Double = 1) -> Color {
        guard let hex = Int(hex.trimmingCharacters(in: .alphanumerics.inverted), radix: 16) else {
            return fallbackColors[nickname.count % fallbackColors.count]
        }
        return Color(hex: hex, opacity: opacity)
    }
}
