import AVFoundation
import UIKit

/// AVPlayerLayer 기반 비디오 재생 뷰
final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    private var player: AVPlayer?
    private var loopObserver: Any?

    var isMuted: Bool = true {
        didSet { player?.isMuted = isMuted }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        playerLayer.backgroundColor = UIColor.clear.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Play

    func play(data: Data) {
        cleanup()

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)

        let url = VideoCompressor.cachedTempFileURL(from: data)
        let player = AVPlayer(url: url)
        player.isMuted = isMuted
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        self.player = player

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }

        player.play()
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func cleanup() {
        player?.pause()
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
        playerLayer.player = nil
        player = nil
    }

    deinit {
        cleanup()
    }
}
