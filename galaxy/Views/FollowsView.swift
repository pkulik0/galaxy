//
//  FollowsView.swift
//  galaxy
//
//  Created by pkulik0 on 17/07/2022.
//

import SwiftUI
import SwiftTwitchAPI

struct FollowsView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    @State private var selectedStream: SwiftTwitchAPI.StreamResponse?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(twitchManager.followedStreams) { stream in
                        HStack {
                            ZStack(alignment: .bottomLeading) {
                                AsyncImage(url: twitchManager.getImageURL(urlString: stream.thumbnailURL, width: 150, height: 85))
                                    .frame(width: 150, height: 85)
                                
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(stream.viewerCount.prettyPrinted())
                                        .font(.footnote)
                                        .foregroundColor(.primary)
                                }
                                .padding(5)
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text(stream.userName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(stream.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .foregroundColor(.secondary)
                                Text(stream.gameName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .onTapGesture {
                            selectedStream = stream
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .fullScreenCover(item: $selectedStream) { stream in
                StreamView(channelName: stream.userName)
            }
            .navigationBarTitle("Following")
        }
    }
}
