//
//  FollowsView.swift
//  galaxy
//
//  Created by pkulik0 on 17/07/2022.
//

import SwiftUI
import SwiftTwitchAPI
import SDWebImageSwiftUI

struct FollowsView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    @State private var selectedStream: SwiftTwitchAPI.Stream?
    
    private let thumbnailSize: (Int, Int) = (150, 85)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(twitchManager.followedStreams) { stream in
                        HStack {
                            ZStack(alignment: .bottomLeading) {
                                AsyncImage(url: TwitchManager.getThumbnailURL(urlString: stream.thumbnailURL, width: thumbnailSize.0 * 2, height: thumbnailSize.1 * 2)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                    } else if phase.error != nil {
                                        Image(systemName: "exclamationmark")
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: CGFloat(thumbnailSize.0), height: CGFloat(thumbnailSize.1))
                                
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
                                    .lineLimit(2)
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
                if let user = twitchManager.user {
                    StreamView(stream: stream, user: user).onAppear {
                        twitchManager.fetchChannelBadges(channelID: stream.userID)
                        twitchManager.fetchChannelEmotes(channelID: stream.userID)
                    }
                }
            }
            .navigationBarTitle("Following")
        }
    }
}
