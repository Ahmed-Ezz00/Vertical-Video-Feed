//
//  FeedsView.swift
//  Vertical Video Feed
//
//  Created by Ahmed Ezz on 06/07/2026.
//

import SwiftUI

// MARK: - FeedsView
struct FeedsView: View {
    let viewModel: FeedsViewModel
    @State private var scrollPosition: Int?

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.videos.enumerated()), id: \.offset) { index, _ in
                    VideoView(viewModel: viewModel, scrollIndex: index)
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrollPosition)
        .ignoresSafeArea()
        .onChange(of: scrollPosition) { _, index in
            viewModel.changeVideo(at: index)
        }
        .task {
            await viewModel.fetchVideos()
        }
    }
}

// MARK: - Preview
#Preview {
    FeedsView(viewModel: .init(service: VideoService(), playbackManager: VideoPlaybackManager()))
}
