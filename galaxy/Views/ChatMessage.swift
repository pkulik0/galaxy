//
//  ChatMessage.swift
//  galaxy
//
//  Created by pkulik0 on 19/07/2022.
//

import SwiftUI
import SwiftTwitchIRC
import WrappingHStack
import SDWebImageSwiftUI

struct ChatMessage: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    @State private var parsedMessage: [MessageElement] = []
    
    @Environment(\.colorScheme) private var colorScheme
    
    let message: SwiftTwitchIRC.ChatMessage
    let channelID: String
    
    func parseMessage() {
        parsedMessage = []
        let isSystemMessage = message.userLogin.isEmpty
        
        if !isSystemMessage {
            for (name, level) in message.badges.sorted(by: <) {
                let badge = twitchManager.getBadge(name: name, level: String(level), channelID: channelID)
                guard let badge = badge else {
                    return
                }

                parsedMessage.append(badge)
            }
            
            let userColor = Color.fromHexString(hex: message.color, nickname: message.userName, isDarkMode: colorScheme == .dark)
            let username = MessageElement.plain(text: "\(message.displayableName): ", color: userColor)
            parsedMessage.append(username)
            
            if twitchManager.deletedMessageIDs.contains(message.id) {
                let deletedMessage = MessageElement.plain(text: "<Deleted message>", color: .secondary)
                parsedMessage.append(deletedMessage)
                return
            }
        }
        
        for word in message.text.split(separator: " ") {
            let word = String(word)
            
            if let emote = twitchManager.getEmote(name: word, channelID: channelID) {
                parsedMessage.append(emote)
            } else {
                let plainText = MessageElement.plain(text: "\(word) ", color: isSystemMessage ? .secondary : .primary)
                parsedMessage.append(plainText)
            }
        }
    }
    
    var body: some View {
        WrappingHStack(parsedMessage.indices, id: \.self, spacing: .constant(0)) { index in
            switch parsedMessage[index] {
            case .plain(text: let text, color: let color):
                Text(text)
                    .foregroundColor(color)
            case .emote(_, url: let url):
                AnimatedImage(url: URL(string: url))
                    .resizable()
                    .playbackMode(.bounce)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                    .padding(.trailing, 3)
            case .badge(_, _, url: let urlString):
                WebImage(url: URL(string: urlString))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 20)
                    .padding(.trailing, 3)
            case .newLine:
                NewLine()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .font(.subheadline)
        .onAppear {
            parseMessage()
        }
        .onChange(of: twitchManager.deletedMessageIDs) { deletedMessagesIDs in
            if deletedMessagesIDs.contains(message.id) {
                print("i was deleted")
                parseMessage()
            }
        }
    }
}
