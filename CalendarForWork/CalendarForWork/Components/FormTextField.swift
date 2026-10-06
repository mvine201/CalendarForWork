import UIKit

final class FormTextField: UITextField {
    init(placeholder: String, systemImageName: String? = nil) {
        super.init(frame: .zero)
        configure(placeholder: placeholder, systemImageName: systemImageName)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure(placeholder: "", systemImageName: nil)
    }

    private func configure(placeholder: String, systemImageName: String?) {
        self.placeholder = placeholder
        textColor = AppTheme.Colors.textPrimary
        tintColor = AppTheme.Colors.amber
        font = .systemFont(ofSize: 16)
        backgroundColor = AppTheme.Colors.card
        layer.borderColor = AppTheme.Colors.border.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = AppTheme.Radius.small
        autocorrectionType = .no
        autocapitalizationType = .none
        heightAnchor.constraint(equalToConstant: 52).isActive = true

        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))

        if let systemImageName = systemImageName {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 52))
            let imageView = UIImageView(image: UIImage(systemName: systemImageName))
            imageView.tintColor = AppTheme.Colors.textSecondary
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 14, y: 15, width: 20, height: 22)
            container.addSubview(imageView)
            leftView = container
        } else {
            leftView = padding
        }

        leftViewMode = .always
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        rightViewMode = .always
    }
}
