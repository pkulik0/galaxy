//
//  galaxyApp.swift
//  galaxy
//
//  Created by pkulik0 on 27/06/2022.
//

import SwiftUI
import SwiftTwitchAPI
import SDWebImage

@main
struct galaxyApp: App {
    let twitchManager = TwitchManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(twitchManager)
                .onAppear {
                    SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
                }
        }
    }
}
