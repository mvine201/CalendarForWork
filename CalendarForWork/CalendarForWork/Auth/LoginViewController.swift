import UIKit

final class LoginViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let emailField = FormTextField(placeholder: "Email", systemImageName: "envelope")
    private let passwordField = FormTextField(placeholder: "Mật khẩu", systemImageName: "lock")
    private let signInButton = PrimaryButton(type: .system)
    private let statusBanner = StatusBannerView()
    private let registerButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Đăng nhập"
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

        let brandView = makeBrandView()
        let titleLabel = UIFactory.titleLabel("CalendarForWork")
        let subtitleLabel = UIFactory.subtitleLabel("Quản lý công việc theo lịch với giao diện doanh nghiệp rõ ràng, trang trọng.")

        signInButton.setTitle("Đăng nhập", for: .normal)
        registerButton.setTitle("Tạo tài khoản mới", for: .normal)
        registerButton.setTitleColor(AppTheme.Colors.navy, for: .normal)
        registerButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)

        contentStack.addArrangedSubview(brandView)
        contentStack.setCustomSpacing(AppTheme.Spacing.lg, after: brandView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.setCustomSpacing(AppTheme.Spacing.lg, after: subtitleLabel)
        contentStack.addArrangedSubview(statusBanner)
        contentStack.addArrangedSubview(emailField)
        contentStack.addArrangedSubview(passwordField)
        contentStack.addArrangedSubview(signInButton)
        contentStack.addArrangedSubview(registerButton)
    }

    private func makeBrandView() -> UIView {
        let container = UIView()
        container.backgroundColor = AppTheme.Colors.navy
        container.layer.cornerRadius = AppTheme.Radius.medium
        container.heightAnchor.constraint(equalToConstant: 108).isActive = true

        let mark = UIImageView(image: UIImage(systemName: "calendar.badge.clock"))
        mark.tintColor = AppTheme.Colors.amber
        mark.contentMode = .scaleAspectFit
        mark.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Lịch công việc"
        label.textColor = .white
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(mark)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            mark.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: AppTheme.Spacing.lg),
            mark.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            mark.widthAnchor.constraint(equalToConstant: 42),
            mark.heightAnchor.constraint(equalToConstant: 42),
            label.leadingAnchor.constraint(equalTo: mark.trailingAnchor, constant: AppTheme.Spacing.md),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -AppTheme.Spacing.lg),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func configureActions() {
        signInButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(showRegister), for: .touchUpInside)
    }

    private func configureKeyboard() {
        scrollView.keyboardDismissMode = .interactive
        emailField.returnKeyType = .done
        passwordField.returnKeyType = .done
        emailField.delegate = self
        passwordField.delegate = self
        enableKeyboardDismissOnTap()
        observeKeyboardForScrollView(scrollView)
    }

    @objc private func handleLogin() {
        view.endEditing(true)
        statusBanner.hide()

        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            statusBanner.show(message: "Nhập email và mật khẩu để tiếp tục.")
            return
        }

        signInButton.setLoading(true, title: "Đăng nhập")

        APIClient.shared.login(LoginRequest(email: email, password: password)) { [weak self] result in
            guard let self = self else { return }
            self.signInButton.setLoading(false, title: "Đăng nhập")

            switch result {
            case .success(let response):
                SessionStore.shared.save(token: response.token, email: response.user.email)
                AppCoordinator.showMainInterface()
            case .failure(let error):
                self.statusBanner.show(message: error.localizedDescription)
            }
        }
    }

    @objc private func showRegister() {
        navigationController?.pushViewController(RegisterViewController(), animated: true)
    }
}
