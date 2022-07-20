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
    
    @State var parsedMessages: [MessageContent] = []
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            ForEach(message.badges.sorted(by: >), id: \.key) { badge, level in
                CachedAsyncImage(url: twitchManager.getBadgeURL(badgeName: badge, channelID: channelID, level: level))
            }
            
            Text(message.userName)
                .foregroundColor(Color.fromHexString(hex: message.color, nickname: message.userName))
            +
            Text(": ")

            ForEach(parsedMessages.indices, id: \.self) { index in
                Group {
                    if let uiImage = parsedMessages[index].uiImage {
                        Text(Image(uiImage: uiImage))
                    } else {
                        Text(parsedMessages[index].text)
                    }
                }
                .task {
                    if let url = parsedMessages[index].url {
                        parsedMessages[index].uiImage = await twitchManager.downloadImage(from: url)
                    }
                }
            }
            
            Spacer()
        }
        .font(.callout)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            parsedMessages = twitchManager.parseMessageContent(messageText: message.text)
            print(parsedMessages)
        }
    }
}
