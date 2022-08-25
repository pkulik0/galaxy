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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(twitchManager.followedStreams) { stream in
                        StreamView(stream: stream)
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
                    PlayerView(stream: stream, user: user).onAppear {
                        twitchManager.fetchChannelBadges(channelID: stream.userID)
                        twitchManager.fetchChannelEmotes(channelID: stream.userID)
                    }
                }
            }
            .navigationBarTitle("Following")
        }
    }
}
