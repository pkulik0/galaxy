//
//  PlayerViewModel.swift
//  galaxy
//
//  Created by pkulik0 on 03/08/2022.
//

import SwiftUI
import SwiftTwitchIRC
import SwiftTwitchAPI
import AVKit

extension PlayerView {
    class ViewModel: ObservableObject {
        @Published var stream: SwiftTwitchAPI.Stream
        var user: SwiftTwitchAPI.User
        var token: String
        
        @Published var streams: [String:String] = [:]
        @Published var quality = ""

        @Published var showPlayer = true
        @Published var lockChat = true
        
        @Published var messageText = ""
                
        lazy var irc: SwiftTwitchIRC = SwiftTwitchIRC(username: user.login, token: token, onMessageReceived: receiveChatMessage, onWhisperReceived: receiveWhisper, onNoticeReceived: receiveNotice, onUserNoticeReceived: receiveUserNotice, onUserStateChanged: handleUserState, onRoomStateChanged: saveRoomState, onClearChat: clearChat, onClearMessage: clearMessage)
        
        @Published var ircMessages: [SwiftTwitchIRC.ChatMessage] = [SwiftTwitchIRC.ChatMessage(id: UUID().uuidString, chatroom: "", userID: "", userName: "", userLogin: "", badges: [:], color: "", text: "Connecting to the chat...")]
        @Published var deletedMessageIDs: [String] = []
        let bufferSize = 100
        
        var notices: [SwiftTwitchIRC.Notice] = []
        var userNotices: [SwiftTwitchIRC.UserNotice] = []
        var whispers: [SwiftTwitchIRC.Whisper] = []
        
        var pendingMessages: [String: [String]] = [:]
        var roomStates: [String: SwiftTwitchIRC.RoomState] = [:]
        
        init(stream: SwiftTwitchAPI.Stream, user: SwiftTwitchAPI.User, token: String) {
            self.user = user
            self.stream = stream
            self.token = token
        }
        
        var sortedStreamsKeys: [String] {
            func parseQuality(_ quality: String) -> Int {
                let index = quality.lastIndex(of: "p") ?? quality.endIndex
                return Int(quality[..<index]) ?? 0
            }
            
            return streams.keys.sorted { lhs, rhs in
                let lhsParsed = parseQuality(lhs)
                let rhsParsed = parseQuality(rhs)
                
                if lhsParsed == rhsParsed {
                    return lhs.count > rhs.count
                }
                return lhsParsed > rhsParsed
            }
        }
        
        @Published var avplayer: AVPlayer?
        
        var playerSize: CGSize {
            let width = UIScreen.main.bounds.width
            let heigth = UIScreen.main.bounds.width / 16 * 9
            return CGSize(width: width, height: heigth)
        }
        
        @Published var dragOffset: CGSize = CGSize.zero
        
        func sendMessage() {
            guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            
            irc.sendMessage(message: messageText, channel: stream.userLogin)
            
            if pendingMessages.keys.contains(stream.userID) {
                pendingMessages[stream.userLogin] = []
            }
            pendingMessages[stream.userLogin]?.append(messageText)
            
            messageText = ""
        }
        
        func resetQuality() {
            quality = sortedStreamsKeys.first ?? ""
        }
        
        func updatePlayer() {
            print("up 1")
            guard let streamUrlString = streams[quality] else {
                return
            }

            guard let url = URL(string: streamUrlString) else {
                return
            }

            if let avplayer = avplayer {
                avplayer.replaceCurrentItem(with: AVPlayerItem(url: url))
                return
            }
            
            avplayer = AVPlayer(url: url)
            avplayer?.play()
            print("up 2")
        }
        
        func fetchStreams() async -> [String:String] {
            guard let url = URL(string: "http://192.168.0.122:5000/\(stream.userLogin)") else {
                print("Invalid url")
                return [:]
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if var decodedData = try? JSONDecoder().decode([String:String].self, from: data) {
                    decodedData.removeValue(forKey: "worst")
                    decodedData.removeValue(forKey: "best")
                    return decodedData
                }
            } catch {
                print("Invaild data")
            }
            return [:]
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
                  let text = pendingMessages[userState.chatroom]?.first
            else {
                return
            }
        
            let message = SwiftTwitchIRC.ChatMessage(id: messageID, chatroom: userState.chatroom, userID: user.id, userName: userState.userName, userLogin: userState.userName, badges: userState.badges, color: userState.color, text: text)
            
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
    }
}
