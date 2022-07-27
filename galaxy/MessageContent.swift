//
//  MessageContent.swift
//  galaxy
//
//  Created by pkulik0 on 26/07/2022.
//

import SwiftUI

enum MessageElement: Equatable {
    case plain(text: String, color: Color)
    case emote(name: String, url: String)
    case badge(name: String, level: String, url: String)
}
