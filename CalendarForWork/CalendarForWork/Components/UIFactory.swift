import UIKit

enum UIFactory {
    static func titleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = AppTheme.Colors.navy
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.numberOfLines = 0
        return label
    }

    static func subtitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = AppTheme.Colors.textSecondary
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.numberOfLines = 0
        return label
    }

    static func iconButton(systemName: String, target: Any?, action: Selector) -> UIBarButtonItem {
        UIBarButtonItem(
            image: UIImage(systemName: systemName),
            style: .plain,
            target: target,
            action: action
        )
    }
}

extension UIView {
    func pinEdges(to other: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom)
        ])
    }
}
