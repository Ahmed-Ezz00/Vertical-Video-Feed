//
//  CustomAVPlayerView.swift
//  Vertical Video Feed
//
//  Created by Ahmed Ezz on 06/07/2026.
//

import AVFoundation
import SwiftUI

// MARK: - CustomAVPlayerView
struct CustomAVPlayerView: UIViewRepresentable {

    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        return view
    }
    
    func updateUIView(_ uiView: PlayerView, context: Context) {
        guard uiView.player !== player else { return }
        uiView.player = player
    }
}

// MARK: - PlayerView
final class PlayerView: UIView {

    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
