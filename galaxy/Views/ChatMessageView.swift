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
    var text: String
    var color: Color?
    var uiImage: UIImage?
}

struct ChatMessageView: View {
    @EnvironmentObject var twitchManager: TwitchManager
    @State var parsedMessages: [MessageContent] = []
    
    let message: SwiftTwitchIRC.ChatMessage
    let channelID: String
    
    func parseMessage() {
        parsedMessages = []
        for (name, level) in message.badges.sorted(by: <) {
            let badge = twitchManager.getBadge(name: name, level: String(level), channelID: channelID)
            guard let badge = badge else {
                return
            }

            let parsed = MessageContent(text: ".", uiImage: badge.image)
            parsedMessages.append(parsed)
        }
        
        let userColor = Color.fromHexString(hex: message.color, nickname: message.userName)
        let username = MessageContent(text: "\(message.userName): ", color: userColor)
        parsedMessages.append(username)
        
        for word in message.text.split(separator: " ") {
            let word = String(word)
            
            let emote = twitchManager.getEmote(name: word, channelID: channelID)
            let parsed = MessageContent(text: "\(word) ", uiImage: emote?.image)
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
        }
        .fixedSize(horizontal: false, vertical: true)
        .font(.body)
        .onAppear {
            parseMessage()
        }
    }
}
