//
//  RootView.swift
//  galaxy
//
//  Created by pkulik0 on 17/07/2022.
//

import SwiftUI

struct RootView: View {
    @State private var selectedTab = "follows"

    var body: some View {
        TabView(selection: $selectedTab) {
            FollowsView()
                .tabItem {
                    Image(systemName: "heart.fill")
                        .tint(.purple)
                    Text("Follows")
                }
                .tag("follows")
            
            DiscoverView()
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("Discover")
                }
                .tag("discover")
        }
    }
}
