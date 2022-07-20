//
//  Images.swift
//  galaxy
//
//  Created by pkulik0 on 20/07/2022.
//

import UIKit

extension UIImage {
    static let cachedImages = NSCache<NSString, UIImage>()
    
    static func download(from url: URL) async -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        
        if let uiImage = cachedImages.object(forKey: cacheKey) {
            return uiImage
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let uiImage =  UIImage(data: data)
            if let uiImage = uiImage {
                cachedImages.setObject(uiImage, forKey: cacheKey)
            }
            
            return uiImage
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
