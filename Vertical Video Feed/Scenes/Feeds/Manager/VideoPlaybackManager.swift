//
//  VideoPlaybackManager.swift
//  Vertical Video Feed
//
//  Created by Ahmed Ezz on 07/07/2026.
//

import AVFoundation
import Combine

@MainActor
class VideoPlaybackManager {
    
    // MARK: - Properties
    
    private let preloadDistance: Int
    private let maxCachedItems: Int
    private let forwardBufferDuration: TimeInterval = 3.0
    
    private let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
    
    private var loopCancellable: AnyCancellable?
    private var statusCancellable: AnyCancellable?
    private var playerCancellable: AnyCancellable?
    private var currentIndex: Int?
    
    private var itemBufferCancellables = Set<AnyCancellable>()
    private var cachedVideoURLs: [URL?] = []
    private var videoItems: [Int: AVPlayerItem] = [:]
    
    private(set) var preloadTasks: [Int: Task<Void, Never>] = [:]
    
    let player = AVPlayer()
    
    // MARK: - Initialization
    
    init(preloadDistance: Int = 2, maxCachedItems: Int = 10) {
        self.preloadDistance = preloadDistance
        self.maxCachedItems = maxCachedItems
        self.observeOnPlayerStatus()
        self.player.automaticallyWaitsToMinimizeStalling = true
    }
    
    // MARK: - Deinitialization
    
    deinit {
        preloadTasks.values.forEach { $0.cancel() }
        statusCancellable?.cancel()
        loopCancellable?.cancel()
        playerCancellable?.cancel()
        itemBufferCancellables.removeAll()
    }
}

// MARK: - Helper Methods
private extension VideoPlaybackManager {
    
    func playerItem(for index: Int) -> AVPlayerItem? {
        if let item = videoItems[index] {
            if item.status == .failed {
                videoItems.removeValue(forKey: index)
            } else {
                return item
            }
        }
        
        guard cachedVideoURLs.indices.contains(index), let url = cachedVideoURLs[index] else {
            return nil
        }
        
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        let asset = AVURLAsset(url: url, options: options)
        let item = AVPlayerItem(asset: asset)
        
        item.preferredForwardBufferDuration = forwardBufferDuration
        videoItems[index] = item
        return item
    }
    
    func clearCache() {
        videoItems.removeAll()
        cachedVideoURLs.removeAll()
        preloadTasks.values.forEach { $0.cancel() }
        preloadTasks.removeAll()
        playerCancellable?.cancel()
        cancelObservations()
        player.replaceCurrentItem(with: nil)
        currentIndex = nil
    }
    
    func observeToPlayVideoOnFinish(item: AVPlayerItem) {
        loopCancellable = NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.player.seek(to: .zero)
                self?.player.play()
                self?.stateSubject.value = .playing
            }
    }
    
    func observeOnItemStatus(item: AVPlayerItem, at index: Int) {
        statusCancellable = item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .failed:
                    let errorDescription = item.error?.localizedDescription ?? "The video failed to load"
                    self?.videoItems.removeValue(forKey: index)
                    self?.stateSubject.value = .failed(errorDescription)
                    
                case .readyToPlay:
                    if self?.currentIndex == index {
                        self?.player.play()
                        self?.stateSubject.value = .playing
                    }
                    
                default:
                    break
                }
            }
    }
    
    func observeOnPlayerStatus() {
        playerCancellable = player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                
                if case .failed = self?.stateSubject.value { return }
                
                switch status {
                case .waitingToPlayAtSpecifiedRate:
                    self?.stateSubject.value = .loading
                    
                case .playing:
                    self?.stateSubject.value = .playing
                    
                case .paused:
                    guard self?.stateSubject.value == .playing else { return }
                    self?.stateSubject.value = .paused
                    
                default:
                    break
                }
            }
    }
    
    func observePlaybackStalled(item: AVPlayerItem, at index: Int) {
        NotificationCenter.default
            .publisher(
                for: .AVPlayerItemPlaybackStalled,
                object: item
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard self?.currentIndex == index else { return }
                self?.stateSubject.value = .loading
            }
            .store(in: &itemBufferCancellables)

        item.publisher(for: \.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keepUp in
                
                guard self?.currentIndex == index else { return }
                
                if keepUp {
                    self?.player.play()
                    self?.stateSubject.value = .playing
                } else {
                    if self?.player.timeControlStatus != .paused {
                        self?.stateSubject.value = .loading
                    }
                }
            }
            .store(in: &itemBufferCancellables)
    }
    
    func trimVideoCache(around index: Int) {
        guard videoItems.count > maxCachedItems else {
            return
        }
        
        let sortedItems = videoItems.keys.sorted {
            abs($0 - index) > abs($1 - index)
        }
        
        let itemsToRemove = videoItems.count - maxCachedItems
        
        for key in sortedItems.prefix(itemsToRemove) {
            if key != currentIndex {
                videoItems.removeValue(forKey: key)
            }
        }
    }
    
    func cancelObservations() {
        loopCancellable?.cancel()
        statusCancellable?.cancel()
        itemBufferCancellables.removeAll()
    }
}

// MARK: - Background Processing
private extension VideoPlaybackManager {
    
    static func performBackgroundPreload(for url: URL, bufferDuration: TimeInterval) async -> AVPlayerItem? {
        let asset = AVURLAsset(url: url)
        
        do {
            let isPlayable = try await asset.load(.isPlayable)
            guard isPlayable else { return nil }
            guard !Task.isCancelled else { return nil }
            
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = bufferDuration
            return item
        } catch {
            return nil
        }
    }
}

// MARK: - VideoPlaybackManagerProtocol Implementation
extension VideoPlaybackManager: VideoPlaybackManagerProtocol {
    
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    func configure(with urls: [URL?]) {
        self.clearCache()
        self.cachedVideoURLs = urls
    }
    
    func playVideo(at index: Int) {
        self.currentIndex = index
        self.player.replaceCurrentItem(with: nil)
        self.cancelObservations()
        
        guard let item = playerItem(for: index) else { return }
        self.stateSubject.value = .loading
        
        self.player.replaceCurrentItem(with: item)
        self.player.seek(to: .zero)
        self.player.play()
        
        observeToPlayVideoOnFinish(item: item)
        observeOnItemStatus(item: item, at: index)
        observePlaybackStalled(item: item, at: index)
    }
    
    func preloadVideos(around index: Int) {
        let targets = (1...preloadDistance).flatMap { [index + $0, index - $0] }
        
        for number in targets {
            guard cachedVideoURLs.indices.contains(number) else { continue }
            guard videoItems[number] == nil else { continue }
            guard preloadTasks[number] == nil else { continue }
            guard let url = cachedVideoURLs[number] else { continue }
            
            let bufferDuration = forwardBufferDuration
            
            preloadTasks[number] = Task {[weak self] in
                defer { self?.preloadTasks.removeValue(forKey: number) }
                
                guard let preloadedItem = await Self.performBackgroundPreload(for: url, bufferDuration: bufferDuration) else { return }
                guard !Task.isCancelled else { return }
                
                self?.videoItems[number] = preloadedItem
            }
        }
    }
    
    func refreshCache(around index: Int) {
        let range = (index - preloadDistance)...(index + preloadDistance)
        videoItems = videoItems.filter { range.contains($0.key) }
        
        trimVideoCache(around: index)

        preloadTasks.forEach { key, task in
            if !range.contains(key) {
                task.cancel()
            }
        }
        
        preloadTasks = preloadTasks.filter { range.contains($0.key) }
    }
    
    func toggleMute(isMuted: Bool) {
        player.isMuted = isMuted
    }
    
    func togglePlay(isPlaying: Bool) {
        _ = isPlaying ? player.play() : player.pause()
        stateSubject.value = isPlaying ? .playing: .paused
    }
}

// MARK: - VideoPlaybackManagerProtocol
protocol VideoPlaybackManagerProtocol {
    var player: AVPlayer { get }
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { get }
    func configure(with urls: [URL?])
    func playVideo(at index: Int)
    func preloadVideos(around index: Int)
    func refreshCache(around index: Int)
    func toggleMute(isMuted: Bool)
    func togglePlay(isPlaying: Bool)
}
