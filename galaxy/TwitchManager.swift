//
//  TwitchManager.swift
//  galaxy
//
//  Created by pkulik0 on 16/07/2022.
//

import Combine
import SwiftTwitchAPI
import Dispatch
import Foundation

class TwitchManager: ObservableObject {
    let api = SwiftTwitchAPI(clientID: "thffseh4mtlmaqnd89rm17ugso8s30", authToken: "3184l994nsn2lgpq8gaup3oe3xifty")
    @Published var user: SwiftTwitchAPI.UserResponse?
    @Published var followedStreams: [SwiftTwitchAPI.StreamResponse] = []
    
    init() {
        api.getUsers { result in
            switch(result) {
            case .success(let response):
                DispatchQueue.main.async {
                    self.user = response.data[0]
                    self.getFollowedStreams()
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
