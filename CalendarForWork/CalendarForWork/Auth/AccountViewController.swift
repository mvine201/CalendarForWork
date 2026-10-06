import UIKit

final class AccountViewController: UIViewController {
    private let contentStack = UIStackView()
    private let statusBanner = StatusBannerView()
    private let usernameLabel = UILabel()
    private let emailLabel = UILabel()
    private let logoutButton = PrimaryButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tài khoản"
        view.backgroundColor = AppTheme.Colors.background
        configureLayout()
        loadAccount()
    }

    private func configureLayout() {
        contentStack.axis = .vertical
        contentStack.spacing = AppTheme.Spacing.md
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.lg),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.lg),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.lg)
        ])

        usernameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        usernameLabel.textColor = AppTheme.Colors.navy
        emailLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        emailLabel.textColor = AppTheme.Colors.textSecondary

        logoutButton.setTitle("Đăng xuất", for: .normal)
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)

        contentStack.addArrangedSubview(makeHeader())
        contentStack.addArrangedSubview(statusBanner)
        contentStack.addArrangedSubview(infoCard(title: "Tên người dùng", label: usernameLabel))
        contentStack.addArrangedSubview(infoCard(title: "Email", label: emailLabel))
        contentStack.addArrangedSubview(logoutButton)
    }

    private func makeHeader() -> UIView {
        let card = UIView()
        card.backgroundColor = AppTheme.Colors.navy
        card.layer.cornerRadius = AppTheme.Radius.medium

        let icon = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        icon.tintColor = AppTheme.Colors.amber
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Thông tin tài khoản"
        label.textColor = .white
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(icon)
        card.addSubview(label)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppTheme.Spacing.lg),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: AppTheme.Spacing.lg),
            icon.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -AppTheme.Spacing.lg),
            icon.widthAnchor.constraint(equalToConstant: 42),
            icon.heightAnchor.constraint(equalToConstant: 42),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: AppTheme.Spacing.md),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -AppTheme.Spacing.lg),
            label.centerYAnchor.constraint(equalTo: icon.centerYAnchor)
        ])

        return card
    }

    private func infoCard(title: String, label: UILabel) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppTheme.Spacing.xs
        stack.backgroundColor = AppTheme.Colors.card
        stack.layer.cornerRadius = AppTheme.Radius.medium
        stack.layoutMargins = UIEdgeInsets(top: AppTheme.Spacing.md, left: AppTheme.Spacing.md, bottom: AppTheme.Spacing.md, right: AppTheme.Spacing.md)
        stack.isLayoutMarginsRelativeArrangement = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = AppTheme.Colors.textSecondary
        titleLabel.font = .systemFont(ofSize: 12, weight: .bold)

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(label)
        return stack
    }

    private func loadAccount() {
        emailLabel.text = SessionStore.shared.userEmail ?? "Đang tải..."
        usernameLabel.text = "Đang tải..."

        APIClient.shared.fetchCurrentUser { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                self.usernameLabel.text = response.user.username
                self.emailLabel.text = response.user.email
            case .failure(let error):
                self.statusBanner.show(message: error.localizedDescription)
                self.usernameLabel.text = "Không tải được"
            }
        }
    }

    @objc private func logout() {
        SessionStore.shared.clear()
        AppCoordinator.showAuthInterface()
    }
}
