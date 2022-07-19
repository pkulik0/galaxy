//
//  TwitchManager.swift
//  galaxy
//
//  Created by pkulik0 on 16/07/2022.
//

import Combine
import SwiftTwitchAPI
import SwiftTwitchIRC
import Dispatch
import Foundation

class TwitchManager: ObservableObject {
    let api = SwiftTwitchAPI(clientID: "thffseh4mtlmaqnd89rm17ugso8s30", authToken: "3184l994nsn2lgpq8gaup3oe3xifty")
    var irc: SwiftTwitchIRC? = nil
    
    @Published var user: SwiftTwitchAPI.UserResponse?
    @Published var followedStreams: [SwiftTwitchAPI.StreamResponse] = []
    
    @Published var ircMessages: [SwiftTwitchIRC.ChatMessage] = []
    var chatMessages: [SwiftTwitchIRC.ChatMessage] {
        return ircMessages.filter({ $0.command == "PRIVMSG" })
    }
    let bufferSize = 200
    
    init() {
        api.getUsers { result in
            switch(result) {
            case .success(let response):
                DispatchQueue.main.async {
                    let user = response.data[0]
                    self.user = user
                    
                    self.getFollowedStreams()
                    self.irc = SwiftTwitchIRC(username: user.login, token: "3184l994nsn2lgpq8gaup3oe3xifty", onMessageReceived: { message in
                        DispatchQueue.main.async {
                            self.ircMessages.append(message)
                            if self.ircMessages.count > self.bufferSize {
                                self.ircMessages.remove(at: 0)
                            }
                        }
                    })
                }
            case .failure(_):
                print("handle me")
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
}
