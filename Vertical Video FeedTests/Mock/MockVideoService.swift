//
//  MockVideoService.swift
//  Vertical Video FeedTests
//
//  Created by Ahmed Ezz on 08/07/2026.
//
import Foundation
@testable import Vertical_Video_Feed

class MockVideoService: VideoServiceProtocol {
    var hasError: Bool = false
    
    func fetchVideos() async -> [VideoModel] {
        guard !hasError else {
            return []
        }
        guard let url = Bundle.test.url(forResource: "Videos", withExtension: "json") else {
            return []
        }
        let data = try? Data(contentsOf: url, options: .mappedIfSafe)
        let videos = try? JSONDecoder().decode([VideoModel].self, from: data ?? .init())
        return videos ?? []
    }
}
