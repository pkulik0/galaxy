//
//  DiscoverView.swift
//  galaxy
//
//  Created by pkulik0 on 20/07/2022.
//

import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    @State private var imageSource: UIImage?
    
    var body: some View {
        VStack {
            if let imageSource = imageSource {
                Image(uiImage: imageSource)
            }
            Text("heh")
                .task {
                    imageSource = await twitchManager.downloadImage(from: twitchManager.getBadgeURL(badgeName: "subscriber", channelID: "", level: 1)!)
                }
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
