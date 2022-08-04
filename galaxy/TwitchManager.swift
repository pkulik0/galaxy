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
    
    @Published var user: SwiftTwitchAPI.User?
    @Published var followedStreams: [SwiftTwitchAPI.Stream] = []
    
    var globalBadges: [MessageElement] = []
    var channelBadges: [String: [MessageElement]] = [:]
    
    var globalEmotes: [MessageElement] = []
    var channelEmotes: [String: [MessageElement]] = [:]
    
    init() {
        api.getUsers { result in
            switch(result) {
            case .success(let response):
                DispatchQueue.main.async { [self] in
                    user = response.data[0]
                    getFollowedStreams()
                }
            case .failure(_):
                print("handle me 1")
            }
        }
        
        fetchGlobalBadges()
        fetchGlobalEmotes()
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
