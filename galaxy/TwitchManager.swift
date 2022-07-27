//
//  TwitchManager.swift
//  galaxy
//
//  Created by pkulik0 on 16/07/2022.
//

import SwiftUI
import SwiftTwitchAPI
import SwiftTwitchIRC
import Dispatch
import Foundation
import UIKit

class TwitchManager: ObservableObject {
    let api = SwiftTwitchAPI(clientID: "thffseh4mtlmaqnd89rm17ugso8s30", authToken: "3184l994nsn2lgpq8gaup3oe3xifty")
    var irc: SwiftTwitchIRC? = nil
    
    @Published var user: SwiftTwitchAPI.User?
    @Published var followedStreams: [SwiftTwitchAPI.Stream] = []
    
    @Published var ircMessages: [SwiftTwitchIRC.ChatMessage] = []
    @Published var deletedMessageIDs: [String] = []
    let bufferSize = 100
    
    @Published var notices: [SwiftTwitchIRC.Notice] = []
    @Published var userNotices: [SwiftTwitchIRC.UserNotice] = []
    @Published var whispers: [SwiftTwitchIRC.Whisper] = []
    
    var globalBadges: [MessageElement] = []
    var channelBadges: [String: [MessageElement]] = [:]
    
    var globalEmotes: [MessageElement] = []
    var channelEmotes: [String: [MessageElement]] = [:]
    
    var pendingMessages: [String: [String]] = [:]
    var roomStates: [String: SwiftTwitchIRC.RoomState] = [:]
    
    init() {
        api.getUsers { result in
            switch(result) {
            case .success(let response):
                DispatchQueue.main.async { [self] in
                    let userResponse = response.data[0]
                    user = userResponse
                    
                    getFollowedStreams()
                    let urlSession = URLSession(configuration: .default)
                    irc = SwiftTwitchIRC(username: userResponse.login, token: "3184l994nsn2lgpq8gaup3oe3xifty", session: urlSession, onMessageReceived: receiveChatMessage, onWhisperReceived: receiveWhisper, onNoticeReceived: receiveNotice, onUserNoticeReceived: receiveUserNotice, onUserStateChanged: handleUserState, onRoomStateChanged: saveRoomState, onClearChat: clearChat, onClearMessage: clearMessage)
                }
            case .failure(_):
                print("handle me 1")
            }
        }
        
        fetchGlobalBadges()
        fetchGlobalEmotes()
    }
    
    func receiveNotice(notice: SwiftTwitchIRC.Notice) {
        let notice = SwiftTwitchIRC.ChatMessage(id: notice.id, chatroom: notice.chatroom, userID: "", userName: "", userLogin: "", badges: [:], color: "", text: notice.text)
        
        DispatchQueue.main.async {
            self.ircMessages.append(notice)
        }
    }
    
    func receiveUserNotice(userNotice: SwiftTwitchIRC.UserNotice) {
        let userNotice = SwiftTwitchIRC.ChatMessage(id: userNotice.id, chatroom: userNotice.chatroom, userID: "", userName: "", userLogin: "", badges: [:], color: "", text: userNotice.text)
        
        DispatchQueue.main.async {
            self.ircMessages.append(userNotice)
        }
    }
    
    func receiveChatMessage(msg: SwiftTwitchIRC.ChatMessage) {
        DispatchQueue.main.async { [self] in
            ircMessages.append(msg)
            if ircMessages.count > bufferSize {
                let removedMessage = ircMessages.remove(at: 0)
                deletedMessageIDs.removeAll(where: { $0 == removedMessage.id })
            }
        }
    }
    
    func receiveWhisper(whisper: SwiftTwitchIRC.Whisper) {
        DispatchQueue.main.async {
            self.whispers.append(whisper)
        }
    }
    
    func handleUserState(userState: SwiftTwitchIRC.UserState) {
        guard let messageID = userState.messageID,
              let userID = user?.id,
              let text = pendingMessages[userState.chatroom]?.first
        else {
            return
        }
    
        let message = SwiftTwitchIRC.ChatMessage(id: messageID, chatroom: userState.chatroom, userID: userID, userName: userState.userName, userLogin: userState.userName, badges: userState.badges, color: userState.color, text: text)
        
        DispatchQueue.main.async {
            self.ircMessages.append(message)
        }
        
        pendingMessages[userState.chatroom]?.removeFirst()
    }
    
    func saveRoomState(roomState: SwiftTwitchIRC.RoomState) {
        DispatchQueue.main.async {
            self.roomStates[roomState.chatroom] = roomState
        }
    }
    
    func clearChat(clearChatInfo: SwiftTwitchIRC.ClearChat) {
        guard let targetUserID = clearChatInfo.targetUserID else {
            let clearChat = SwiftTwitchIRC.ChatMessage(id: clearChatInfo.id, chatroom: clearChatInfo.chatroom, userID: "", userName: "", userLogin: "", badges: [:], color: "", text: "The chat was cleared by a moderator.")
            DispatchQueue.main.async {
                self.ircMessages = [clearChat]
                self.deletedMessageIDs = []
            }
            return
        }

        for msg in ircMessages {
            if clearChatInfo.chatroom == msg.chatroom, targetUserID == msg.userID {
                DispatchQueue.main.async {
                    self.deletedMessageIDs.append(msg.id)
                }
            }
        }
    }
    
    func clearMessage(clearMessageInfo: SwiftTwitchIRC.ClearMessage) {
        DispatchQueue.main.async {
            self.deletedMessageIDs.append(clearMessageInfo.targetMessageID)
        }
    }
    
    func getThumbnailURL(urlString: String, width: Int, height: Int) -> URL? {
        let urlString = urlString
            .replacingOccurrences(of: "{width}", with: "\(width)")
            .replacingOccurrences(of: "{height}", with: "\(height)")
        return URL(string: urlString)
    }
    
    func getFollowedStreams() {
        guard let user = user else {
            return
        }
        
        api.getFollowedStreams(userID: user.id) { result in
            switch(result) {
            case .success(let response):
                DispatchQueue.main.async {
                    self.followedStreams = response.data
                }
                break
            case .failure(_):
                print("handle me 2")
            }
        }
    }
    
    private func parseBadges(badges: [SwiftTwitchAPI.Badge], channelID: String? = nil) {
        for badge in badges {
            for version in badge.versions {
                let parsedBadge = MessageElement.badge(name: badge.setID, level: version.id, url: version.imageURL2X)
                if let channelID = channelID {
                    self.channelBadges[channelID]?.append(parsedBadge)
                } else {
                    self.globalBadges.append(parsedBadge)
                }
            }
        }
    }
    
    func fetchGlobalBadges() {
        api.getGlobalBadges { result in
            switch(result) {
            case .success(let response):
                self.parseBadges(badges: response.data)
            case .failure(_):
                print("handle me 3")
            }
        }
    }
    
    func fetchChannelBadges(channelID: String) {
        if channelBadges.keys.contains(channelID) {
            return
        }
        channelBadges[channelID] = []
        
        api.getChannelBadges(broadcasterID: channelID) { result in
            switch(result) {
            case .success(let response):
                self.parseBadges(badges: response.data, channelID: channelID)
            case .failure(_):
                print("handle me 4")
            }
        }
    }
    
    private func parseEmotes(emotes: [SwiftTwitchAPI.TEmote], channelID: String? = nil) {
        for emote in emotes {
            var emoteURL = ""
            emote.urls.forEach { urlEntry in
                if urlEntry.size == .the1X || urlEntry.size == .the2X {
                    emoteURL = urlEntry.url
                    return
                }
            }
            let parsedEmote = MessageElement.emote(name: emote.code, url: emoteURL)
            if let channelID = channelID {
                self.channelEmotes[channelID]?.append(parsedEmote)
            } else {
                self.globalEmotes.append(parsedEmote)
            }
        }
    }
    
    func fetchGlobalEmotes() {
        api.getAllGlobalEmotes { result in
            switch(result) {
            case .success(let emotes):
                self.parseEmotes(emotes: emotes)
                break
            case .failure(_):
                print("handle me 6")
            }
        }
    }
    
    func fetchChannelEmotes(channelID: String) {
        if channelEmotes.keys.contains(channelID) {
            return
        }
        channelEmotes[channelID] = []
        
        api.getAllChannelEmotes(channelID: channelID) { result in
            switch(result) {
            case .success(let emotes):
                self.parseEmotes(emotes: emotes, channelID: channelID)
            case .failure(_):
                print("handle me 7")
            }
        }
    }
    
    func getEmote(name: String, channelID: String? = nil) -> MessageElement? {
        if let channelID = channelID, let emotes = channelEmotes[channelID] {
            for emote in emotes {
                switch emote {
                case .emote(name: let emoteName, _):
                    if emoteName == name {
                        return emote
                    }
                default:
                    continue
                }
            }
        }
        
        for emote in globalEmotes {
            switch emote {
            case .emote(name: let emoteName, _):
                if emoteName == name {
                    return emote
                }
            default:
                continue
            }
        }
        
        return nil
    }
    
    func getBadge(name: String, level: String, channelID: String? = nil) -> MessageElement? {
        if let channelID = channelID, let badges = channelBadges[channelID] {
            for badge in badges {
                switch badge {
                case .badge(name: let emoteName, level: let emoteLevel, _):
                    if name == emoteName && level == emoteLevel {
                        return badge
                    }
                default:
                    continue
                }
            }
        }
        
        for badge in globalBadges {
            switch badge {
            case .badge(name: let emoteName, level: let emoteLevel, _):
                if name == emoteName && level == emoteLevel {
                    return badge
                }
            default:
                continue
            }
        }
        
        return nil
    }
}
