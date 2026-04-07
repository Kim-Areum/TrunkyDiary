import AVFoundation
import UIKit

/// AVPlayerLayer 기반 비디오 재생 뷰
final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    private var player: AVPlayer?
    private var loopObserver: Any?
    private var readyObserver: NSKeyValueObservation?

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
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = isMuted
        self.player = player

        // playerLayer를 숨긴 상태로 연결
        playerLayer.opacity = 0
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }

        // readyToPlay 후 첫 프레임 seek → 레이어 보이기 → 재생
        readyObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .readyToPlay, let self = self else { return }
            self.readyObserver = nil
            self.player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                guard let self = self else { return }
                self.playerLayer.opacity = 1
                self.player?.play()
            }
        }
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func cleanup() {
        player?.pause()
        readyObserver?.invalidate()
        readyObserver = nil
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
        playerLayer.player = nil
        playerLayer.opacity = 0
        player = nil
    }

    deinit {
        cleanup()
    }
}
