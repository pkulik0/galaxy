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
    
    @Published var user: SwiftTwitchAPI.UserResponse?
    @Published var followedStreams: [SwiftTwitchAPI.StreamResponse] = []
    
    @Published var ircMessages: [SwiftTwitchIRC.ChatMessage] = []
    let bufferSize = 200
    
    struct Badge {
        let name: String
        let level: String
        var image: UIImage?
    }
    
    var globalBadges: [Badge] = []
    var channelBadges: [String: [Badge]] = [:]
    
    struct Emote {
        let name: String
        var image: UIImage?
    }
    
    var globalEmotes: [Emote] = []
    var channelEmotes: [String: [Emote]] = [:]

    
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
    
    private func parseBadges(badges: [SwiftTwitchAPI.BadgeResponse], channelID: String? = nil) {
        for badge in badges {
            for version in badge.versions {
                Task {
                    var parsedBadge = Badge(name: badge.setID, level: version.id)
                    guard let url = URL(string: version.imageURL1X),
                          let data = await Data.download(from: url)
                    else {
                        return
                    }
                    parsedBadge.image = UIImage(data: data)
                    
                    if let channelID = channelID {
                        self.channelBadges[channelID]!.append(parsedBadge)
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
    
    private func parseEmotes(emotes: [SwiftTwitchAPI.EmoteResponse], channelID: String? = nil) {
        for emote in emotes {
            Task {
                var parsedEmote = Emote(name: emote.name)
                guard let url = URL(string: emote.images.url1X),
                      let data = await Data.download(from: url)
                else {
                    return
                }

                parsedEmote.image = UIImage(data: data)
                if let channelID = channelID {
                    self.channelEmotes[channelID]!.append(parsedEmote)
                } else {
                    self.globalEmotes.append(parsedEmote)
                }
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
    }
    
    func getEmote(name: String, channelID: String? = nil) -> Emote? {
        if let channelID = channelID,
           let emote = channelEmotes[channelID]?.first(where: { $0.name == name }) {
            return emote
        }
        return globalEmotes.first(where: { $0.name == name })
    }
    
    func getBadge(name: String, level: String, channelID: String? = nil) -> Badge? {
        if let channelID = channelID,
           let badge = channelBadges[channelID]?.first(where: { $0.name == name && $0.level == level }) {
            return badge
        }
        return globalBadges.first(where: { $0.name == name && $0.level == level })
    }
}
