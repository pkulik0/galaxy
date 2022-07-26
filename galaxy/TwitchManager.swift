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
    let bufferSize = 100
    
    var globalBadges: [MessageElement] = []
    var channelBadges: [String: [MessageElement]] = [:]
    
    var globalEmotes: [MessageElement] = []
    var channelEmotes: [String: [MessageElement]] = [:]

    
    init() {
        api.getUsers { result in
            switch(result) {
            case .success(let response):
                DispatchQueue.main.async { [self] in
                    let userResponse = response.data[0]
                    user = userResponse
                    
                    getFollowedStreams()
                    let urlSession = URLSession(configuration: .default)
                    irc = SwiftTwitchIRC(username: userResponse.login, token: "3184l994nsn2lgpq8gaup3oe3xifty", session: urlSession, onMessageReceived: receiveChatMessage, onWhisperReceived: nil, onNoticeReceived: nil, onUserNoticeReceived: nil, onUserStateChanged: nil, onRoomStateChanged: nil, onClearChat: nil, onClearMessage: nil)
                }
            case .failure(_):
                print("handle me")
            }
        }
        
        fetchGlobalBadges()
        fetchGlobalEmotes()
    }
    
    func receiveChatMessage(msg: SwiftTwitchIRC.ChatMessage) {
        DispatchQueue.main.async { [self] in
            ircMessages.append(msg)
            if ircMessages.count > bufferSize {
                ircMessages.remove(at: 0)
            }
        }
    }
    
    func getImageURL(urlString: String, width: Int, height: Int) -> URL? {
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
                print("handle me")
            }
        }
    }
    
    private func parseBadges(badges: [SwiftTwitchAPI.Badge], channelID: String? = nil) {
        for badge in badges {
            for version in badge.versions {
                Task {
                    guard let url = URL(string: version.imageURL2X),
                          let data = await Data.download(from: url)
                    else {
                        return
                    }
                    
                    let parsedBadge = MessageElement.badge(name: badge.setID, level: version.id, imageData: data)
                    if let channelID = channelID {
                        self.channelBadges[channelID]?.append(parsedBadge)
                    } else {
                        self.globalBadges.append(parsedBadge)
                    }
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
                print("handle me")
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
                print("handle me")
            }
        }
    }
    
    private func parseEmotes(emotes: [SwiftTwitchAPI.Emote], channelID: String? = nil) {
        for emote in emotes {
            Task {
                guard let url = URL(string: emote.images.url2X),
                      let data = await Data.download(from: url)
                else {
                    return
                }

                let parsedEmote = MessageElement.emote(name: emote.name, imageData: data, animated: false, provider: .twitch)
                if let channelID = channelID, var channelEmotes = self.channelEmotes[channelID] {
                    channelEmotes.append(parsedEmote)
                } else {
                    self.globalEmotes.append(parsedEmote)
                }
            }
        }
    }
    
    private func parseEmotes(emotes: [SwiftTwitchAPI.BttvEmote], channelID: String? = nil) {
        for emote in emotes {
            Task {
                guard let url = URL(string: emote.getUrlString(size: .the2X)),
                      let data = await Data.download(from: url)
                else {
                    return
                }
                
                let parsedEmote = MessageElement.emote(name: emote.code, imageData: data, animated: emote.imageType == .gif, provider: .bttv)
                if let channelID = channelID, var channelEmotes = self.channelEmotes[channelID] {
                    channelEmotes.append(parsedEmote)
                } else {
                    self.globalEmotes.append(parsedEmote)
                }
            }
        }
    }
    
    private func parseEmotes(emotes: [SwiftTwitchAPI.FFZEmote], channelID: String) {
        for emote in emotes {
            Task {
                guard let url = URL(string: emote.images.the2X ?? emote.images.the1X),
                      let data = await Data.download(from: url)
                else {
                    return
                }
                
                let parsedEmote = MessageElement.emote(name: emote.code, imageData: data, animated: emote.imageType == .gif, provider: .ffz)
                channelEmotes[channelID]?.append(parsedEmote)
            }
        }
    }
    
    private func parseEmotes(emotes: [SwiftTwitchAPI.SevenTVEmote], channelID: String) {
        for emote in emotes {
            Task {
                guard let url = URL(string: emote.urls[1][1]),
                      let data = await Data.download(from: url)
                else {
                    return
                }
                
                let parsedEmote = MessageElement.emote(name: emote.name, imageData: data, animated: true, provider: .sevenTv)
                channelEmotes[channelID]?.append(parsedEmote)
            }
        }
    }
    
    func fetchGlobalEmotes() {
        api.getGlobalEmotes { result in
            switch(result) {
            case .success(let response):
                self.parseEmotes(emotes: response.data)
            case .failure(_):
                print("handle me")
            }
        }
        api.getBttvGlobalEmotes { result in
            switch(result) {
            case .success(let response):
                self.parseEmotes(emotes: response)
                break
            case .failure(_):
                print("handle me")
            }
        }
    }
    
    func fetchChannelEmotes(channelID: String) {
        if channelEmotes.keys.contains(channelID) {
            return
        }
        channelEmotes[channelID] = []
        
        api.getChannelEmotes(broadcasterID: channelID) { result in
            switch(result) {
            case .success(let response):
                self.parseEmotes(emotes: response.data, channelID: channelID)
            case .failure(_):
                print("handle me")
            }
        }
        api.getBttvChannelData(channelID: channelID) { result in
            switch(result) {
            case .success(let response):
                self.parseEmotes(emotes: response.channelEmotes, channelID: channelID)
                self.parseEmotes(emotes: response.sharedEmotes, channelID: channelID)
            case .failure(_):
                print("handle me")
            }
        }
        api.getFFZEmotes(channelID: channelID) { result in
            switch(result) {
            case .success(let response):
                self.parseEmotes(emotes: response, channelID: channelID)
            case .failure(_):
                print("handle me")
            }
        }
        api.getSevenTVEmotes(channelID: channelID) { result in
            switch(result) {
            case .success(let response):
                self.parseEmotes(emotes: response, channelID: channelID)
            case .failure(_):
                print("handle me")
            }
        }
    }
    
    func getEmote(name: String, channelID: String? = nil) -> MessageElement? {
        if let channelID = channelID, let emotes = channelEmotes[channelID] {
            for emote in emotes {
                switch emote {
                case .emote(name: let emoteName, _, animated: _, provider: _):
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
            case .emote(name: let emoteName, _, animated: _, provider: _):
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
