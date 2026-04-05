import UIKit

/// iCloud 동기화 진행 중 상단에 표시되는 플로팅 배너
final class CloudSyncBanner: UIView {

    // MARK: - Static

    private static weak var current: CloudSyncBanner?

    static func show() {
        guard current == nil else { return }
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })
        else { return }

        let banner = CloudSyncBanner()
        current = banner
        banner.present(in: window)
    }

    static func dismiss() {
        current?.dismissAnimated()
    }

    static func showError(_ message: String) {
        dismiss()
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })
        else { return }

        let banner = CloudSyncBanner(errorMessage: message)
        current = banner
        banner.present(in: window)

        // 3초 후 자동 dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if current === banner {
                banner.dismissAnimated()
            }
        }
    }

    // MARK: - Views

    private let spinner = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel()
    private let stitchLayer = CAShapeLayer()
    private let cornerRadius: CGFloat = 12

    private var isError = false

    // MARK: - Init

    private init() {
        super.init(frame: .zero)
        setup()
    }

    private convenience init(errorMessage: String) {
        self.init()
        isError = true
        spinner.stopAnimating()
        spinner.isHidden = true

        let errorIcon = UIImageView(image: UIImage(systemName: "exclamationmark.icloud")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        ))
        errorIcon.tintColor = UIColor(hex: "D05050")
        errorIcon.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(errorIcon, belowSubview: messageLabel)

        NSLayoutConstraint.activate([
            errorIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            errorIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        messageLabel.text = errorMessage
        messageLabel.textColor = UIColor(hex: "D05050")
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        backgroundColor = DS.bgNeutral
        layer.cornerRadius = cornerRadius
        clipsToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 4

        // Stitch border
        stitchLayer.fillColor = UIColor.clear.cgColor
        stitchLayer.strokeColor = DS.stitch.cgColor
        stitchLayer.lineWidth = 1
        stitchLayer.lineDashPattern = [3, 3]
        stitchLayer.lineCap = .round
        layer.addSublayer(stitchLayer)

        // Spinner
        spinner.color = DS.fgNeutral
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        // Label
        messageLabel.text = "iCloud 동기화 중..."
        messageLabel.font = DS.font(12)
        messageLabel.textColor = DS.fgStrong
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            spinner.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.widthAnchor.constraint(equalToConstant: 18),
            spinner.heightAnchor.constraint(equalToConstant: 18),

            messageLabel.leadingAnchor.constraint(equalTo: spinner.trailingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let stitchRect = bounds.insetBy(dx: 3, dy: 3)
        stitchLayer.path = UIBezierPath(roundedRect: stitchRect, cornerRadius: 9).cgPath
    }

    // MARK: - Present / Dismiss

    private func present(in window: UIWindow) {
        translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(self)

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: window.centerXAnchor),
            topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 7),
            widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, constant: -36),
        ])

        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -20)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    private func dismissAnimated() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -20)
        } completion: { _ in
            self.removeFromSuperview()
            if CloudSyncBanner.current === self {
                CloudSyncBanner.current = nil
            }
        }
    }
}
