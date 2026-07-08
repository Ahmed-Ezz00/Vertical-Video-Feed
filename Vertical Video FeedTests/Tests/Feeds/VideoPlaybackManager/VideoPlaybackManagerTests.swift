//
//  VideoPlaybackManagerTests.swift
//  Vertical Video FeedTests
//
//  Created by Ahmed Ezz on 08/07/2026.
//

import XCTest
import AVFoundation
@testable import Vertical_Video_Feed

@MainActor
final class VideoPlaybackManagerTests: XCTestCase {
    private let preloadDistance = 3
    private var mockVideoPlayerManager: VideoPlaybackManager!
    
    override func setUpWithError() throws {
        mockVideoPlayerManager = VideoPlaybackManager(preloadDistance: preloadDistance)
        let urls = getMockURLS()
        mockVideoPlayerManager.configure(with: urls)
    }
    
    override func tearDownWithError() throws {
        mockVideoPlayerManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - PlayVideo_whenIndexIsntExist_itemShouldntExist
    func test_playVideo_whenIndexIsntExist_itemShouldntExist() {
        // Given
        var playerItem: AVPlayerItem? = AVPlayerItem(url: .init(string: "https://apple.com")!)
        
        // When
        mockVideoPlayerManager.playVideo(at: 100)
        playerItem = mockVideoPlayerManager.player.currentItem
        
        // Then
        XCTAssertNil(playerItem)
    }
    
    // MARK: - PlayVideo_whenIndexIsExist_itemShouldExist
    func test_playVideo_whenIndexIsExist_itemShouldExist() {
        // Given
        var playerItem: AVPlayerItem?
        
        // When
        mockVideoPlayerManager.playVideo(at: 4)
        playerItem = mockVideoPlayerManager.player.currentItem
        
        // Then
        XCTAssertNotNil(playerItem)
    }
    
    // MARK: - PlayVideo_onSpecificIndex_itemURLShouldBeSame
    func test_playVideo_onSpecificIndex_itemURLShouldBeSame() {
        // Given
        let specificIndex = 4
        let expectedURL = getMockURLS()[specificIndex]
        
        // When
        mockVideoPlayerManager.playVideo(at: specificIndex)
        let itemURL = mockVideoPlayerManager.player.currentItem?.asset as? AVURLAsset
        
        // Then
        XCTAssertEqual(itemURL?.url, expectedURL)
    }
    
    // MARK: - PlayVideo_whenIndexIsExist_itemShouldPlay
    func test_playVideo_whenIndexIsExist_itemShouldPlay() {
        // Given
        var isItemPlay = false
        
        // When
        mockVideoPlayerManager.playVideo(at: 4)
        let status = mockVideoPlayerManager.player.timeControlStatus
        isItemPlay = status == .playing || status == .waitingToPlayAtSpecifiedRate
        
        // Then
        XCTAssertTrue(isItemPlay)
    }
    
    // MARK: - PlayVideo_whenItemIsMute_itemShouldntHaveSound
    func test_playVideo_whenItemIsMute_itemShouldntHaveSound() {
        // Given
        var itemIsMuted = false
        
        // When
        mockVideoPlayerManager.playVideo(at: 4)
        mockVideoPlayerManager.toggleMute(isMuted: true)
        itemIsMuted = mockVideoPlayerManager.player.isMuted

        // Then
        XCTAssertTrue(itemIsMuted)
    }
    
    // MARK: - PlayVideo_whenItemIsPaused_itemShouldPause
    func test_playVideo_whenItemIsPaused_itemShouldPause() {
        // Given
        var isItemPaused = false
        
        // When
        mockVideoPlayerManager.playVideo(at: 4)
        mockVideoPlayerManager.togglePlay(isPlaying: false)
        let status = mockVideoPlayerManager.player.timeControlStatus
        isItemPaused = status == .paused
        
        // Then
        XCTAssertTrue(isItemPaused)
    }
    
    // MARK: - LoopVideo_whenVideoIsFinished_itemShouldStartAgain
    func test_loopVideo_whenVideoIsFinished_itemShouldStartAgain() async {
        // Given
        let player = mockVideoPlayerManager.player
        var isVideoStartAgain = false
        
        // When
        mockVideoPlayerManager.playVideo(at: 0)
        NotificationCenter.default.post(
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        try? await Task.sleep(for: .milliseconds(100))
        let currentTime = CMTimeGetSeconds((player.currentTime()))
        isVideoStartAgain = currentTime == 0
        // Then
        XCTAssertTrue(isVideoStartAgain)
    }
    
    // MARK: - PreloadVideos_aroundSpecificIndex_videosShouldPrepared
    func test_preloadVideos_aroundSpecificIndex_videosShouldPrepared() async {
        // Given
        let specificIndex = 4
        let expectedPreloadIndexResult = [1,2,3,5,6,7]

        // When
        mockVideoPlayerManager.preloadVideos(around: specificIndex)
        let preloadIndexResult = mockVideoPlayerManager.preloadTasks.keys.sorted()

        // Then
        XCTAssertEqual(preloadIndexResult, expectedPreloadIndexResult)
    }
    
    // MARK: - PreloadVideos_whenTasksStartedAroundIndexThenIndexChanged_oldTaksShouldBeRemoved
    func test_preloadVideos_whenTasksStartedAroundIndexThenIndexChanged_oldTaksShouldBeRemoved() async {
        // Given
        let specificIndex = 0
        let expectedPreloadIndexResult = [1,2,3]
        let expectedCurrentPreloadIndexResult = [7,8,9,11,12,13]
        
        // When
        mockVideoPlayerManager.preloadVideos(around: 10)
        let currentPreloadTasksIndex = mockVideoPlayerManager.preloadTasks.keys.sorted()
        mockVideoPlayerManager.refreshCache(around: specificIndex)
        mockVideoPlayerManager.preloadVideos(around: specificIndex)
        let preloadIndexResult = mockVideoPlayerManager.preloadTasks.keys.sorted()

        // Then
        XCTAssertEqual(currentPreloadTasksIndex, expectedCurrentPreloadIndexResult)
        XCTAssertEqual(preloadIndexResult, expectedPreloadIndexResult)
    }
}

private extension VideoPlaybackManagerTests {
    func getMockURLS() -> [URL?] {
        guard let url = Bundle.test.url(forResource: "Videos", withExtension: "json") else {
            return []
        }
        let data = try? Data(contentsOf: url, options: .mappedIfSafe)
        let videos = try? JSONDecoder().decode([VideoModel].self, from: data ?? .init())
        return videos?.map { $0.url } ?? []
    }
}
