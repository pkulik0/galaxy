//
//  Images.swift
//  galaxy
//
//  Created by pkulik0 on 20/07/2022.
//

import UIKit

extension UIImage {
    static func download(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
