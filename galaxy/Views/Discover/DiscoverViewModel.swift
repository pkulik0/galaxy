//
//  DiscoverViewModel.swift
//  galaxy
//
//  Created by pkulik0 on 07/09/2022.
//

import SwiftUI
import SwiftTwitchAPI

extension DiscoverView {
    @MainActor
    class ViewModel: ObservableObject {
        
        
        init() {
            getStreams()
            getCategories()
        }
        
        
    }
}
