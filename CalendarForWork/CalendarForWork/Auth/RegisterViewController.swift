import UIKit

final class RegisterViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let usernameField = FormTextField(placeholder: "Tên người dùng", systemImageName: "person")
    private let emailField = FormTextField(placeholder: "Email", systemImageName: "envelope")
    private let passwordField = FormTextField(placeholder: "Mật khẩu", systemImageName: "lock")
    private let submitButton = PrimaryButton(type: .system)
    private let statusBanner = StatusBannerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Đăng ký"
        view.backgroundColor = AppTheme.Colors.background
        passwordField.isSecureTextEntry = true
        configureLayout()
        configureActions()
        configureKeyboard()
    }

    private func configureLayout() {
        view.addSubview(scrollView)
        scrollView.pinEdges(to: view)

        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = AppTheme.Spacing.md
        contentStack.alignment = .fill

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: AppTheme.Spacing.xl),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: AppTheme.Spacing.lg),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -AppTheme.Spacing.lg),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppTheme.Spacing.xl)
        ])

        let badge = makeBadgeView()
        let titleLabel = UIFactory.titleLabel("Tạo tài khoản")
        let subtitleLabel = UIFactory.subtitleLabel("Mỗi email chỉ được dùng cho một tài khoản. Hãy dùng email cơ quan để quản lý công việc tập trung.")

        submitButton.setTitle("Đăng ký", for: .normal)

        contentStack.addArrangedSubview(badge)
        contentStack.setCustomSpacing(AppTheme.Spacing.lg, after: badge)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.setCustomSpacing(AppTheme.Spacing.lg, after: subtitleLabel)
        contentStack.addArrangedSubview(statusBanner)
        contentStack.addArrangedSubview(usernameField)
        contentStack.addArrangedSubview(emailField)
        contentStack.addArrangedSubview(passwordField)
        contentStack.addArrangedSubview(submitButton)
    }

    private func makeBadgeView() -> UIView {
        let container = UIView()
        container.backgroundColor = AppTheme.Colors.navy
        container.layer.cornerRadius = AppTheme.Radius.medium
        container.heightAnchor.constraint(equalToConstant: 84).isActive = true

        let icon = UIImageView(image: UIImage(systemName: "building.2.crop.circle"))
        icon.tintColor = AppTheme.Colors.amber
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Truy cập doanh nghiệp"
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(icon)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: AppTheme.Spacing.lg),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 36),
            icon.heightAnchor.constraint(equalToConstant: 36),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: AppTheme.Spacing.md),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -AppTheme.Spacing.lg),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func configureActions() {
        submitButton.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
    }

    private func configureKeyboard() {
        scrollView.keyboardDismissMode = .interactive
        usernameField.returnKeyType = .done
        emailField.returnKeyType = .done
        passwordField.returnKeyType = .done
        usernameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        enableKeyboardDismissOnTap()
        observeKeyboardForScrollView(scrollView)
    }

    @objc private func handleRegister() {
        view.endEditing(true)
        statusBanner.hide()

        guard let username = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), username.count >= 3,
              let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
              let password = passwordField.text, password.count >= 6 else {
            statusBanner.show(message: "Tên người dùng từ 3 ký tự, mật khẩu từ 6 ký tự và email hợp lệ.")
            return
        }

        submitButton.setLoading(true, title: "Đăng ký")

        let request = RegisterRequest(username: username, email: email, password: password)
        APIClient.shared.register(request) { [weak self] result in
            guard let self = self else { return }
            self.submitButton.setLoading(false, title: "Đăng ký")

            switch result {
            case .success(let response):
                SessionStore.shared.save(token: response.token, email: response.user.email)
                AppCoordinator.showMainInterface()
            case .failure(let error):
                self.statusBanner.show(message: error.localizedDescription)
            }
        }
    }
}
