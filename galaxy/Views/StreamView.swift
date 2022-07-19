//
//  ContentView.swift
//  galaxy
//
//  Created by pkulik0 on 27/06/2022.
//

import SwiftUI
import AVKit
import SwiftTwitchAPI
import CachedAsyncImage

struct StreamView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    @State var stream: SwiftTwitchAPI.StreamResponse
    
    @State private var streams: [String:String] = [:]
    @State private var quality = ""

    @State private var showPlayer = true
    @State private var lockChat = true
    
    @Environment(\.dismiss) private var dismiss
    
    private var sortedStreamsKeys: [String] {
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
    
    @State private var avplayer: AVPlayer?
    
    private var playerSize: CGSize {
        let width = UIScreen.main.bounds.width
        let heigth = UIScreen.main.bounds.width / 16 * 9
        return CGSize(width: width, height: heigth)
    }
    
    @State private var dragOffset: CGSize = CGSize.zero
    
    var dragToClose: some Gesture {
        DragGesture()
            .onEnded { value in
                if value.translation.height > 100 {
                    dismiss()
                } else {
                    dragOffset = .zero
                }
            }
            .onChanged { value in
                withAnimation {
                    if value.translation.height > 0 {
                        dragOffset.height = value.translation.height
                    }
                }
            }
    }
    
    var chatGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    lockChat = false
                }
            }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if showPlayer {
                    Group {
                        if let avplayer = avplayer {
                            VideoPlayer(player: avplayer)
                        } else {
                            ZStack {
                                Color(uiColor: UIColor.systemBackground)
                                ProgressView()
                            }
                        }
                    }
                    .frame(width: playerSize.width, height: playerSize.height)
                } else {
                    Button {
                        quality = sortedStreamsKeys.first ?? ""
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title2)
                            
                            VStack {
                                Text("Audio Only Mode")
                                    .font(.headline)
                                Text("Tap to disable.")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.primary.opacity(0.1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .simultaneousGesture(dragToClose)
            .zIndex(.infinity)
            .onChange(of: quality) { quality in
                updatePlayer()
                withAnimation {
                    showPlayer = quality != "audio_only"
                }
            }
            
            HStack(spacing: 5) {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text(stream.userName)
                
                Spacer()
                
                Menu {
                    Picker("Quality", selection: $quality) {
                        ForEach(sortedStreamsKeys, id: \.self) { quality in
                            if quality == "audio_only" {
                                Label("Audio Only", systemImage: "speaker.wave.2.fill")
                            } else {
                                Text(quality)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            
            Divider()
            
            ScrollViewReader { reader in
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: 3) {
                            ForEach(twitchManager.chatMessages) { message in
                                ChatMessageView(message: message, channelID: stream.userID)
                            }
                            Color.clear.id("bottom")
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                    }
                    .simultaneousGesture(chatGesture)
                    .onChange(of: twitchManager.chatMessages) { _ in
                        if lockChat {
                            withAnimation {
                                reader.scrollTo("bottom")
                            }
                        }
                    }
                    
                    if !lockChat {
                        Button("Show latest messages.") {
                            withAnimation {
                                reader.scrollTo("bottom")
                            }
                            lockChat = true
                        }
                        .font(.subheadline)
                        .padding(10)
                        .background(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .padding(.bottom, 5)
                        .buttonStyle(.plain)
                    }
                }
            }
            .onAppear {
                if var irc = twitchManager.irc {
                    twitchManager.ircMessages = []
                    irc.joinChannel(channel: stream.userLogin)
                }
                twitchManager.getChannelBadges(channelID: stream.userID)
            }
            .onDisappear {
                if var irc = twitchManager.irc {
                    irc.leaveChannel(channel: stream.userLogin)
                }
            }
            
            Spacer()
        }
        .offset(dragOffset)
        .task {
            await fetchData()
        }
    }
    
    func updatePlayer() {
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
    }
    
    func fetchData() async {
        guard let url = URL(string: "http://0.0.0.0:5000/\(stream.userName.lowercased())") else {
            print("Invalid url")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if var decodedData = try? JSONDecoder().decode([String:String].self, from: data) {
                decodedData.removeValue(forKey: "worst")
                decodedData.removeValue(forKey: "best")
                streams = decodedData
                quality = "none"
                quality = sortedStreamsKeys.first ?? ""
            }
        } catch {
            print("Invaild data")
        }
    }
}

