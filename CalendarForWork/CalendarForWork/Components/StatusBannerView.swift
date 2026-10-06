import UIKit

final class StatusBannerView: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        numberOfLines = 0
        font = .systemFont(ofSize: 14, weight: .semibold)
        layer.cornerRadius = AppTheme.Radius.small
        layer.masksToBounds = true
        textAlignment = .center
        isHidden = true
    }

    func show(message: String, isError: Bool = true) {
        text = "  \(message)  "
        textColor = isError ? AppTheme.Colors.danger : AppTheme.Colors.success
        backgroundColor = isError ? AppTheme.Colors.danger.withAlphaComponent(0.10) : AppTheme.Colors.success.withAlphaComponent(0.10)
        isHidden = false
    }

    func hide() {
        isHidden = true
        text = nil
    }
}
