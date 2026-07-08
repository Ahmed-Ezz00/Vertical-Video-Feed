//
//  VideoService.swift
//  Vertical Video Feed
//
//  Created by Ahmed Ezz on 06/07/2026.
//

import Foundation

// MARK: - VideoService
class VideoService: VideoServiceProtocol {
    func fetchVideos() async -> [VideoModel] {
        guard let url = Bundle.main.url(forResource: "Videos", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let videos = try JSONDecoder().decode([VideoModel].self, from: data)
            return videos
        } catch {
            print("Error parsing JSON: \(error)")
            return []
        }
    }
}

// MARK: - VideoServiceProtocol
protocol VideoServiceProtocol: AnyObject {
    func fetchVideos() async -> [VideoModel]
}
