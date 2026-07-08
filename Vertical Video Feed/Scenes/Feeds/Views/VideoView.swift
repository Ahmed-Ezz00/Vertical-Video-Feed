//
//  VideoView.swift
//  Vertical Video Feed
//
//  Created by Ahmed Ezz on 06/07/2026.
//

import SwiftUI
import AVKit

// MARK: - VideoView
struct VideoView: View {
    let viewModel: FeedsViewModel
    let scrollIndex: Int
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
            
            if viewModel.currentIndex == scrollIndex {
                ZStack {
                    CustomAVPlayerView(player: viewModel.player)
                        .clipped()
                        .onTapGesture {
                            viewModel.togglePlayButton()
                        }
                    StateView(playbackState: viewModel.playbackState, action: viewModel.retryCurrentVideo)
                }
                MuteButton(isMuted: viewModel.isMuted, playbackState: viewModel.playbackState, action: viewModel.toggleMuteButton)
            } else {
                Color.black
            }
        }
        .containerRelativeFrame([.horizontal, .vertical])
    }
}

// MARK: - MuteButton
private struct MuteButton: View {
    let isMuted: Bool
    let playbackState: PlaybackState
    let action: () -> Void
    
    var body: some View {
        if playbackState == .playing || playbackState == .paused {
            Button(action: action) {
                Image(systemName: isMuted ? "speaker.slash.fill": "speaker.wave.2.fill")
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 60)
            .padding(.trailing, 20)
        }
    }
}

// MARK: - StateView
private struct StateView: View {
    let playbackState: PlaybackState
    let action: () -> Void

    var body: some View {
        if playbackState == .loading {
            LoadingView()
        } else if case .failed(let errorMessage) = playbackState {
            FailedView(errorMessage: errorMessage, action: action)
        }
    }
}

// MARK: - LoadingView
private struct LoadingView: View {
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
            .shadow(radius: 5)
    }
}

// MARK: - FailedView
private struct FailedView: View {
    let errorMessage: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42))
                .foregroundColor(.yellow)
            
            Text(errorMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: action) {
                Text("Retry")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(Color.white, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }
}

// MARK: - Preview
#Preview {
    VideoView(viewModel: .init(service: VideoService(), playbackManager: VideoPlaybackManager()), scrollIndex: 0)
}
