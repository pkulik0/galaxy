//
//  ChatMessageView.swift
//  galaxy
//
//  Created by pkulik0 on 19/07/2022.
//

import SwiftUI
import SwiftTwitchIRC
import CachedAsyncImage

struct ChatMessageView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    
    @State var message: SwiftTwitchIRC.ChatMessage
    @State var channelID: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            ForEach(message.badges.sorted(by: >), id: \.key) { badge, level in
                CachedAsyncImage(url: twitchManager.getBadgeURL(badgeName: badge, channelID: channelID, level: level))
            }
            
            Text(message.userName)
                .foregroundColor(Color.fromHexString(hex: message.color, nickname: message.userName))
            +
            Text(": ")
            +
            Text(message.text)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .font(.callout)
        .fixedSize(horizontal: false, vertical: true)
    }
}
