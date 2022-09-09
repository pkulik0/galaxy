//
//  PlayerView.swift
//  galaxy
//
//  Created by pkulik0 on 27/06/2022.
//

import SwiftUI
import AVKit
import SwiftTwitchAPI
import SwiftTwitchIRC

struct PlayerView: View {
    @StateObject private var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(stream: SwiftTwitchAPI.Stream, user: SwiftTwitchAPI.User) {
        _viewModel = StateObject(wrappedValue: ViewModel(stream: stream, user: user, token: "3184l994nsn2lgpq8gaup3oe3xifty"))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if viewModel.showPlayer {
                    Group {
                        if let avplayer = viewModel.avplayer {
                            VideoPlayer(player: avplayer)
                        } else {
                            ZStack {
                                Color(uiColor: UIColor.systemBackground)
                                ProgressView()
                            }
                        }
                    }
                    .frame(width: viewModel.playerSize.width, height: viewModel.playerSize.height)
                } else {
                    Button(action: viewModel.resetQuality) {
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
            .onChange(of: viewModel.quality) { quality in
                viewModel.updatePlayer()
                withAnimation {
                    viewModel.showPlayer = quality != "audio_only"
                }
            }
            
            HStack(spacing: 5) {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text(viewModel.stream.userName)
                
                Spacer()
                
                Menu {
                    Picker("Quality", selection: $viewModel.quality) {
                        ForEach(viewModel.sortedStreamsKeys, id: \.self) { quality in
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
                        LazyVStack(spacing: 5) {
                            ForEach(viewModel.ircMessages) { message in
                                ChatMessage(deletedMessagesIDs: $viewModel.deletedMessageIDs, message: message, channelID: viewModel.stream.userID)
                            }
                            Color.clear.id("bottom")
                        }
                        .padding(.leading, 5)
                        .frame(maxWidth: .infinity)
                    }
                    .simultaneousGesture(chatGesture)
                    .onChange(of: viewModel.ircMessages) { _ in
                        if viewModel.lockChat {
                            reader.scrollTo("bottom")
                        }
                    }
                    
                    if !viewModel.lockChat {
                        Button("Show latest messages") {
                            reader.scrollTo("bottom")
                            viewModel.lockChat = true
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
                viewModel.irc.joinChatroom(viewModel.stream.userLogin)
            }
            .onDisappear {
                viewModel.irc.leaveChatroom(viewModel.stream.userLogin)
                viewModel.avplayer = nil
            }
            
            Spacer()
            
            Divider()
            
            HStack {
                TextField("Say something...", text: $viewModel.messageText)
                    .onSubmit(viewModel.sendMessage)
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 5)
        }
        .offset(viewModel.dragOffset)
        .task {
            viewModel.streams = await viewModel.fetchStreams()
            viewModel.resetQuality()
            print(viewModel.streams)
        }
    }
    
    var dragToClose: some Gesture {
        DragGesture()
            .onEnded { [self] value in
                if value.translation.height > 100 {
                    dismiss()
                } else {
                    viewModel.dragOffset = .zero
                }
            }
            .onChanged { [self] value in
                withAnimation {
                    if value.translation.height > 0 {
                        viewModel.dragOffset.height = value.translation.height
                    }
                }
            }
    }
    
    var chatGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    viewModel.lockChat = false
                }
            }
    }
}

