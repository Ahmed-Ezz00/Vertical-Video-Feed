//
//  FeedsViewModelTests.swift
//  Vertical Video FeedTests
//
//  Created by Ahmed Ezz on 08/07/2026.
//

import XCTest
import AVFoundation
@testable import Vertical_Video_Feed

@MainActor
final class FeedsViewModelTests: XCTestCase {
    private var viewModel: FeedsViewModel!
    private var mockService: MockVideoService!
    private var mockVideoPlayerManager: VideoPlaybackManager!
    
    override func setUpWithError() throws {
        mockService = MockVideoService()
        mockVideoPlayerManager = VideoPlaybackManager()
        viewModel = FeedsViewModel(service: mockService, playbackManager: mockVideoPlayerManager)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockService = nil
        mockVideoPlayerManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - FetchVideos_onResponseHasError_onResponseIsEmpty
    func test_fetchVideos_onResponseHasError_onResponseIsEmpty() async {
        // Given
        var isResponseEmpty = false
        
        // When
        mockService.hasError = true
        let _ = await viewModel.fetchVideos()
        isResponseEmpty = viewModel.videos.isEmpty
        
        // Then
        XCTAssertTrue(isResponseEmpty)
    }
    
    // MARK: - FetchVideos_onResponseIsValid_onResponseHasData
    func test_fetchVideos_onResponseIsValid_onResponseHasData() async {
        // Given
        var isResponseHasData = false
        
        // When
        mockService.hasError = false
        let _ = await viewModel.fetchVideos()
        isResponseHasData = !viewModel.videos.isEmpty
        
        // Then
        XCTAssertTrue(isResponseHasData)
    }
    
    // MARK: - PlayVideo_onResponseHasError_itemShouldntExist
    func test_playVideo_onResponseHasError_itemShouldntExist() async {
        // Given
        var currentItemIsNil = false
        
        // When
        mockService.hasError = true
        let _ = await viewModel.fetchVideos()
        currentItemIsNil = viewModel.player.currentItem == nil
        
        // Then
        XCTAssertTrue(currentItemIsNil)
    }
    
    // MARK: - PlayVideo_onResponseHasData_itemShouldExist
    func test_playVideo_onResponseHasData_itemShouldExist() async {
        // Given
        var currentItemIsNonNil = false
        
        // When
        let _ = await viewModel.fetchVideos()
        currentItemIsNonNil = viewModel.player.currentItem != nil
        
        // Then
        XCTAssertTrue(currentItemIsNonNil)
    }
    
    // MARK: - PlayVideo_onResponseHasData_videoShouldPlayAutomatic
    func test_playVideo_onResponseHasData_videoShouldPlayAutomatic() async {
        // Given
        var videoIsPlaying = false
        
        // When
        let _ = await viewModel.fetchVideos()
        let status = viewModel.player.timeControlStatus
        videoIsPlaying = status == .playing || status == .waitingToPlayAtSpecifiedRate
        
        // Then
        XCTAssertTrue(videoIsPlaying)
    }
    
    // MARK: - PlayVideo_onResponseHasData_videoShouldHaveSound
    func test_playVideo_onResponseHasData_videoShouldHaveSound() async {
        // Given
        var videoShouldHaveSound = false
        
        // When
        let _ = await viewModel.fetchVideos()
        videoShouldHaveSound = !viewModel.player.isMuted
        
        // Then
        XCTAssertTrue(videoShouldHaveSound)
    }
    
    // MARK: - PlayVideo_onResponseHasData_firstVideoShouldPlay
    func test_playVideo_onResponseHasData_firstVideoShouldPlay() async {
        // Given
        var isFirstVideoPlaying = false
        
        // When
        let _ = await viewModel.fetchVideos()
        let playerUrl = viewModel.player.currentItem?.asset as? AVURLAsset
        isFirstVideoPlaying = viewModel.videos.first?.url == playerUrl?.url
        
        // Then
        XCTAssertTrue(isFirstVideoPlaying)
    }
    
    // MARK: - ChangeVideo_whenUserScroll_nextVideoShouldPlay
    func test_changeVideo_whenUserScroll_nextVideoShouldPlay() async {
        // Given
        let expectedVideoIndex = 1
        var isNextVideoPlaying = false
        
        // When
        let _ = await viewModel.fetchVideos()
        viewModel.changeVideo(at: expectedVideoIndex)
        let playerUrl = viewModel.player.currentItem?.asset as? AVURLAsset
        isNextVideoPlaying = viewModel.videos[expectedVideoIndex].url == playerUrl?.url
        
        // Then
        XCTAssertTrue(isNextVideoPlaying)
    }
    
    // MARK: - MuteButton_onUserClickMute_videoShouldntHaveSound
    func test_muteButton_onUserClickMute_videoShouldntHaveSound() async {
        // Given
        var videoIsMuted = false
        
        // When
        let _ = await viewModel.fetchVideos()
        viewModel.toggleMuteButton()
        videoIsMuted = viewModel.player.isMuted
        
        // Then
        XCTAssertTrue(videoIsMuted)
    }
    
    // MARK: - PauseButton_onUserClickPause_videoShouldStop
    func test_pauseButton_onUserClickPause_videoShouldStop() async {
        // Given
        var videoIsPaused = false
        
        // When
        let _ = await viewModel.fetchVideos()
        viewModel.togglePlayButton()
        videoIsPaused = viewModel.player.timeControlStatus == .paused
        
        // Then
        XCTAssertTrue(videoIsPaused)
    }
    
    // MARK: - RetryButton_onUserClickRetry_stateShouldBeLoading
    func test_retryButton_onUserClickRetry_stateShouldBeLoading() async {
        // Given
        let wrongURL = URL(string: "https://this-will-fail.com/video.mp4")
        var playbackState: PlaybackState?
        
        // When
        let mockVideoPlayerManager = VideoPlaybackManager()
        mockVideoPlayerManager.configure(with: [wrongURL])
        viewModel.retryCurrentVideo()
        playbackState = viewModel.playbackState

        // Then
        XCTAssertEqual(playbackState, .loading)
    }
}
