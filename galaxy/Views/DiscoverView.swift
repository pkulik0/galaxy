//
//  DiscoverView.swift
//  galaxy
//
//  Created by pkulik0 on 20/07/2022.
//

import SwiftUI
import SwiftTwitchAPI

struct DiscoverView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    
    @State private var topCategories: [SwiftTwitchAPI.Category] = []
    
    @State private var topStreams: [SwiftTwitchAPI.Stream] = []
    @State private var paginationCursor: String?
    
    @State private var selectedStream: SwiftTwitchAPI.Stream?
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top) {
                            ForEach(topCategories) { category in
                                CategoryView(category: category)
                            }
                        }
                        .padding()
                        .fixedSize()
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        Text("Streams")
                            .font(.title2.bold())
                        
                        HStack(spacing: 5) {
                            Text("Filters: ")
                                .font(.caption)
                            
                            Button {
                                print("FILTER SELECTION")
                            } label: {
                                Label("Add filter", systemImage: "plus")
                                    .font(.caption)
                                    .labelStyle(.iconOnly)
                                    .padding(5)
                            }
                            .background(Color.secondary.opacity(0.3))
                            .clipShape(Circle())
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom)
                        
                        LazyVStack(alignment: .leading) {
                            ForEach(topStreams) { stream in
                                StreamView(stream: stream).onTapGesture {
                                    selectedStream = stream
                                }
                            }
                            Color.clear.onAppear {
                                getStreams()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Discover")
            .onAppear(perform: refresh)
            .refreshable {
                topStreams = []
                paginationCursor = nil
                refresh()
            }
            .fullScreenCover(item: $selectedStream) { stream in
                if let user = twitchManager.user {
                    PlayerView(stream: stream, user: user).onAppear {
                        twitchManager.fetchChannelBadges(channelID: stream.userID)
                        twitchManager.fetchChannelEmotes(channelID: stream.userID)
                    }
                }
            }
        }
    }
    
    func refresh() {
        getCategories()
        getStreams()
    }
    
    func getCategories() {
        twitchManager.api.getTopCategories { result in
            switch(result) {
            case .success(let result):
                DispatchQueue.main.async {
                    self.topCategories = result.data
                }
            case .failure(_):
                print("handle me")
            }
        }
    }
    
    func getStreams() {
        twitchManager.api.getStreams(after: paginationCursor) { result in
            switch(result) {
            case .success(let result):
                DispatchQueue.main.async {
                    self.topStreams += result.data
                }
                self.paginationCursor = result.pagination?.cursor
            case .failure(_):
                print("handle me")
            }
        }
    }
}
