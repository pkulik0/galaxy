//
//  ChatMessage.swift
//  galaxy
//
//  Created by pkulik0 on 19/07/2022.
//

import SwiftUI
import SwiftTwitchIRC
import WrappingHStack

struct ChatMessage: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    @State private var parsedMessage: [MessageElement] = []
    
    let message: SwiftTwitchIRC.ChatMessage
    let channelID: String
    
    func parseMessage() {
        parsedMessage = []
        for (name, level) in message.badges.sorted(by: <) {
            let badge = twitchManager.getBadge(name: name, level: String(level), channelID: channelID)
            guard let badge = badge else {
                return
            }

            parsedMessage.append(badge)
        }
        
        let userColor = Color.fromHexString(hex: message.color, nickname: message.userName)
        let username = MessageElement.plain(text: "\(message.displayableName): ", color: userColor)
        parsedMessage.append(username)
        
        for word in message.text.split(separator: " ") {
            let word = String(word)
            
            if let emote = twitchManager.getEmote(name: word, channelID: channelID) {
                parsedMessage.append(emote)
            } else {
                let plainText = MessageElement.plain(text: "\(word) ", color: .primary)
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
            case .emote(name: let name, imageData: let imageData, animated: let animated, provider: let provider):
                if animated {
                    GIFImage(data: imageData, speed: provider == EmoteProvider.sevenTv ? 15.0 : 1.0)
                        .frame(width: 32, height: 32)
                        .padding(.trailing, 3)
                } else if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .padding(.trailing, 3)
                } else {
                    Text(name)
                        .foregroundColor(.red)
                }
            case .badge(name: let name, level: _, imageData: let imageData):
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 3)
                } else {
                    Text(name)
                        .foregroundColor(.red)
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
