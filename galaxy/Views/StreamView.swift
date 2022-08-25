//
//  StreamView.swift
//  galaxy
//
//  Created by pkulik0 on 25/08/2022.
//

import SwiftUI
import SwiftTwitchAPI

struct StreamView: View {
    let stream: SwiftTwitchAPI.Stream
    
    private let thumbnailSize: (Int, Int) = (150, 85)
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: TwitchManager.getThumbnailURL(urlString: stream.thumbnailURL, width: thumbnailSize.0 * 2, height: thumbnailSize.1 * 2)) { phase in
                    if let image = phase.image {
                        image.resizable()
                    } else if phase.error != nil {
                        Image(systemName: "exclamationmark")
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: CGFloat(thumbnailSize.0), height: CGFloat(thumbnailSize.1))
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    
                    Text(stream.viewerCount.prettyPrinted())
                        .font(.footnote)
                        .foregroundColor(.primary)
                }
                .padding(5)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(stream.userName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(stream.title)
                    .font(.subheadline)
                    .lineLimit(2)
                Text(stream.gameName)
                    .font(.caption2.bold())
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Color.secondary.opacity(0.1)))
            }
            .foregroundColor(.secondary)
            Spacer()
        }
    }
}
