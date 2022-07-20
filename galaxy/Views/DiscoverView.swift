//
//  DiscoverView.swift
//  galaxy
//
//  Created by pkulik0 on 20/07/2022.
//

import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var twitchManager: TwitchManager
    @State private var imageSource: UIImage?
    
    var body: some View {
        Text("aha")
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
