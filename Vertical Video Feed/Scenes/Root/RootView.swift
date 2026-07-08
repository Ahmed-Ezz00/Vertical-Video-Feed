//
//  RootView.swift
//  Vertical Video Feed
//
//  Created by Ahmed Ezz on 07/07/2026.
//

import SwiftUI

struct RootView: View {
    @State private var viewModel = FeedsViewModel(
        service: VideoService(),
        playbackManager: VideoPlaybackManager()
    )
    
    var body: some View {
        FeedsView(viewModel: viewModel)
    }
}

#Preview {
    RootView()
}
