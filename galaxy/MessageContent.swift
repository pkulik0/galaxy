//
//  MessageContent.swift
//  galaxy
//
//  Created by pkulik0 on 26/07/2022.
//

import SwiftUI

enum MessageElement {
    case plain(text: String, color: Color)
    case emote(name: String, imageData: Data, animated: Bool, provider: EmoteProvider)
    case badge(name: String, level: String, imageData: Data)
}

enum EmoteProvider {
    case twitch, bttv, ffz, sevenTv
}
