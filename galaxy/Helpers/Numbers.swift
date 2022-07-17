//
//  Numbers.swift
//  galaxy
//
//  Created by pkulik0 on 17/07/2022.
//

extension Int {
    func prettyPrinted() -> String {
        if self > 1000 {
            return "\(String(format: "%.1f", Double(self) / 1000.0))K"
        }
        return String(self)
    }
}
