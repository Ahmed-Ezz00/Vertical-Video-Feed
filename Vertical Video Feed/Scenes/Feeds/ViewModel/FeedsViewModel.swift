//
//  FeedsViewModel.swift
//  Vertical Video Feed
//
//  Created by Ahmed Ezz on 06/07/2026.
//

import AVFoundation
import Combine

@MainActor
@Observable
class FeedsViewModel {
    
    // MARK: - Properties
    
    private let playbackManager: VideoPlaybackManagerProtocol
    private let service: VideoServiceProtocol
    
    private var stateCancellable: AnyCancellable?
    private var isPlaying: Bool = true
    
    private(set) var videos: [VideoModel] = []
    private(set) var isMuted: Bool = false
    private(set) var currentIndex: Int = 0
    private(set) var playbackState: PlaybackState = .idle
    
    var player: AVPlayer { playbackManager.player }
    
    // MARK: - Initialization
    
    init(service: VideoServiceProtocol, playbackManager: VideoPlaybackManagerProtocol) {
        self.service = service
        self.playbackManager = playbackManager
        self.observeToStatusUpdate()
    }
}

// MARK: - Public Helper Methods
extension FeedsViewModel {
    
    func fetchVideos() async {
        let items = await service.fetchVideos()
        videos = items.compactMap { $0 }
        currentIndex = 0
        
        guard !videos.isEmpty else { return }
        
        playbackManager.configure(with: videos.map { $0.url })
        playbackManager.playVideo(at: currentIndex)
        playbackManager.preloadVideos(around: currentIndex)
    }
    
    func changeVideo(at index: Int?) {
        guard let index = index, videos.indices.contains(index) else { return }
        
        currentIndex = index
        isPlaying = true
        
        playbackManager.playVideo(at: index)
        playbackManager.preloadVideos(around: index)
        playbackManager.refreshCache(around: index)
    }
    
    func toggleMuteButton() {
        isMuted.toggle()
        playbackManager.toggleMute(isMuted: isMuted)
    }
    
    func togglePlayButton() {
        isPlaying.toggle()
        playbackManager.togglePlay(isPlaying: isPlaying)
    }
    
    func retryCurrentVideo() {
        playbackState = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.playbackManager.playVideo(at: self.currentIndex)
        }
    }
}

// MARK: - Private Observations
private extension FeedsViewModel {
    
    func observeToStatusUpdate() {
        stateCancellable = playbackManager.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.playbackState = newState
            }
    }
}
