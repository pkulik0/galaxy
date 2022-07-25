//
//  Data.swift
//  galaxy
//
//  Created by pkulik0 on 25/07/2022.
//

import Foundation

extension Data {
    static let cachedImages = NSCache<NSString, NSData>()
    
    static func download(from url: URL) async -> Data? {
        let cacheKey = url.absoluteString as NSString
        
        if let nsData = cachedImages.object(forKey: cacheKey) {
            return Data(referencing: nsData)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let nsData = NSData(data: data)
            cachedImages.setObject(nsData, forKey: cacheKey)
            
            return data
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
