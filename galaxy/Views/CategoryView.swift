//
//  CategoryView.swift
//  galaxy
//
//  Created by pkulik0 on 25/08/2022.
//

import SwiftUI
import SwiftTwitchAPI
import SDWebImageSwiftUI

struct CategoryView: View {
    let category: SwiftTwitchAPI.Category
    
    private let thumnailSize: (Int, Int) = (150, 200)
    
    var body: some View {
        VStack {
            WebImage(url: TwitchManager.getThumbnailURL(urlString: category.boxArtUrl, width: thumnailSize.0, height: thumnailSize.1))

            Text(category.name)
                .font(.body)
        }
        .frame(width: CGFloat(thumnailSize.0))
    }
}
