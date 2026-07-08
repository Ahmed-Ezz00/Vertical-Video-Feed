//
//  PlaybackState.swift
//  Vertical Video Feed
//
//  Created by Ahmed Ezz on 08/07/2026.
//

import Foundation

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case failed(String)
    
    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.playing, .playing), (.paused, .paused):
            return true
        case (.failed(let lMsg), .failed(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}
