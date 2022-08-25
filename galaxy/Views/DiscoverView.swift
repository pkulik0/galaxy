//
//  DiscoverView.swift
//  galaxy
//
//  Created by pkulik0 on 20/07/2022.
//

import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top) {
                            ForEach(twitchManager.topCategories) { category in
                                CategoryView(category: category)
                            }
                        }
                        .padding()
                        .fixedSize()
                    }
                    
                    Text("Streams")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    
                    LazyVStack(alignment: .leading) {
                        ForEach(twitchManager.topStreams) { stream in
                            StreamView(stream: stream)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Discover")
        }
    }
}
