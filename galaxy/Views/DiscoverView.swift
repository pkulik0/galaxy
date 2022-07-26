//
//  DiscoverView.swift
//  galaxy
//
//  Created by pkulik0 on 20/07/2022.
//

import SwiftUI
import SwiftUIGIF

struct DiscoverView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    
    let link = "https://cdn.7tv.app/emote/6287c2ca6d9cd2d1f31b5e7d/2x"
    @State var data: Data? = nil
    
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
