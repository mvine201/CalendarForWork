import UIKit

final class PrimaryButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        layer.cornerRadius = AppTheme.Radius.small
        titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        setTitleColor(AppTheme.Colors.navy, for: .normal)
        setTitleColor(AppTheme.Colors.navy.withAlphaComponent(0.55), for: .disabled)
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.baseBackgroundColor = AppTheme.Colors.amber
        buttonConfiguration.baseForegroundColor = AppTheme.Colors.navy
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        configuration = buttonConfiguration
        heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
    }

    func setLoading(_ isLoading: Bool, title: String) {
        isEnabled = !isLoading
        setTitle(isLoading ? "Đang xử lý..." : title, for: .normal)
        alpha = isLoading ? 0.72 : 1
    }
}
