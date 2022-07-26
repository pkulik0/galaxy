//
//  DiscoverView.swift
//  galaxy
//
//  Created by pkulik0 on 20/07/2022.
//

import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    
    let link = "https://cdn.7tv.app/emote/616ed0485ff09767de299043/2x"
    @State var data: Data? = nil
    @State var isAnimating = true
    
    var body: some View {
        VStack {
            Group {
                if let data = data {
                    GIFImage(data: data, speed: 10)
                } else {
                    ProgressView()
                }
            }
            .frame(height: 32)
        }
        .task {
            guard let url = URL(string: link) else {
                return
            }

            data = await Data.download(from: url)
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
