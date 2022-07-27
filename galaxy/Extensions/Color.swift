//
//  Color.swift
//  galaxy
//
//  Created by pkulik0 on 19/07/2022.
//

import SwiftUI

extension Color {
    init(hex: Int, opacity: Double = 1, isDarkMode: Bool) {
        var red = Double((hex >> 16) & 0xff) / 255
        var green = Double((hex >> 08) & 0xff) / 255
        var blue = Double((hex >> 00) & 0xff) / 255

        if !isDarkMode && red > 0.85 && green > 0.85 && blue > 0.85 {
            red -= 0.4
            green -= 0.4
            blue -= 0.4
        } else if isDarkMode && red < 0.15 && green < 0.15 && blue < 0.15 {
            red += 0.4
            green += 0.4
            blue += 0.4
        }
        
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
        
    static func fromHexString(hex: String, nickname: String, isDarkMode: Bool) -> Color {
        guard let hex = Int(hex.trimmingCharacters(in: .alphanumerics.inverted), radix: 16) else {
            let fallbackColors: [Color] = [.yellow, .blue, .orange, .green, .red, .cyan, .brown, .indigo, .pink, .mint]
            return fallbackColors[nickname.count % fallbackColors.count]
        }
        return Color(hex: hex, isDarkMode: isDarkMode)
    }
}
