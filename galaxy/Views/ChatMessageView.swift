//
//  ChatMessageView.swift
//  galaxy
//
//  Created by pkulik0 on 19/07/2022.
//

import SwiftUI
import SwiftTwitchIRC
import WrappingHStack

struct MessageContent {
    let text: String
    var color: Color?
    var url: URL?
    var uiImage: UIImage?
}

struct ChatMessageView: View {
    @EnvironmentObject var twitchManager: TwitchManager
    @State var parsedMessages: [MessageContent] = []
    
    let message: SwiftTwitchIRC.ChatMessage
    let channelID: String
    
    func parseMessage() {
        parsedMessages = []
        for (badge, level) in message.badges {
            let badgeURL = twitchManager.getBadgeURL(badgeName: badge, channelID: channelID, level: level)
            let parsed = MessageContent(text: badge, url: badgeURL)
            parsedMessages.append(parsed)
        }
        
        let userColor = Color.fromHexString(hex: message.color, nickname: message.userName)
        let username = MessageContent(text: "\(message.userName): ", color: userColor)
        parsedMessages.append(username)
        
        for word in message.text.split(separator: " ") {
            let word = String(word)
            
            let url = twitchManager.getEmoteURL(emoteName: word, channelID: channelID)
            let parsed = MessageContent(text: "\(word) ", url: url)
            parsedMessages.append(parsed)
        }
    }
    
    var body: some View {
        WrappingHStack(parsedMessages.indices, id: \.self, spacing: .constant(0)) { index in
            Group {
                if let uiImage = parsedMessages[index].uiImage {
                    Text(Image(uiImage: uiImage))
                        .padding(.trailing, 3)
                } else {
                    Text(parsedMessages[index].text)
                        .foregroundColor(parsedMessages[index].color ?? .primary)
                }
            }
            .task {
                if let url = parsedMessages[index].url {
                    parsedMessages[index].uiImage = await UIImage.download(from: url)
                }
            }
        }
        .font(.callout)
        .onAppear {
            parseMessage()
        }
    }
}
