import UIKit

final class TaskDetailViewController: UIViewController {
    var onTaskChanged: (() -> Void)?

    private let task: TaskDTO
    private let allowsEditing: Bool
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let statusBanner = StatusBannerView()
    private let confirmButton = PrimaryButton(type: .system)

    init(task: TaskDTO, allowsEditing: Bool) {
        self.task = task
        self.allowsEditing = allowsEditing
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Thông tin"
        view.backgroundColor = AppTheme.Colors.background
        configureNavigation()
        configureLayout()
    }

    private func configureNavigation() {
        if allowsEditing && !task.isCompletedOrOverdue {
            navigationItem.rightBarButtonItem = UIFactory.iconButton(systemName: "square.and.pencil", target: self, action: #selector(showEditTask))
        }
    }

    private func configureLayout() {
        view.addSubview(scrollView)
        scrollView.pinEdges(to: view)

        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = AppTheme.Spacing.md

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: AppTheme.Spacing.lg),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: AppTheme.Spacing.lg),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -AppTheme.Spacing.lg),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppTheme.Spacing.xl)
        ])

        contentStack.addArrangedSubview(makeHeader())
        contentStack.addArrangedSubview(statusBanner)
        contentStack.addArrangedSubview(infoRow(title: "Tên công việc", value: task.name))
        contentStack.addArrangedSubview(infoRow(title: "Mô tả", value: task.description.isEmpty ? "Không có mô tả" : task.description))
        contentStack.addArrangedSubview(infoRow(title: "Mức ưu tiên", value: task.priority.title))
        contentStack.addArrangedSubview(infoRow(title: "Trạng thái", value: task.isCompletedOrOverdue ? "Đã hoàn thành" : task.status.title))
        contentStack.addArrangedSubview(infoRow(title: "Thời gian", value: formattedDate()))
        contentStack.addArrangedSubview(infoRow(title: "Thời lượng", value: formattedDuration()))

        if task.isCompletedOrOverdue {
            statusBanner.show(message: "Công việc đã qua mốc thời gian. Xác nhận hoàn thành để xóa khỏi lịch.", isError: false)
            confirmButton.setTitle("Xác nhận hoàn thành", for: .normal)
            confirmButton.addTarget(self, action: #selector(confirmCompletedTask), for: .touchUpInside)
            contentStack.addArrangedSubview(confirmButton)
        }
    }

    private func makeHeader() -> UIView {
        let card = UIView()
        card.backgroundColor = AppTheme.Colors.navy
        card.layer.cornerRadius = AppTheme.Radius.medium

        let icon = UIImageView(image: UIImage(systemName: task.isCompletedOrOverdue ? "checkmark.seal.fill" : "doc.text.magnifyingglass"))
        icon.tintColor = task.isCompletedOrOverdue ? AppTheme.Colors.success : AppTheme.Colors.amber
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = task.isCompletedOrOverdue ? "Đã hoàn thành" : "Chi tiết công việc"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = task.name
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(icon)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppTheme.Spacing.lg),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: AppTheme.Spacing.lg),
            icon.widthAnchor.constraint(equalToConstant: 34),
            icon.heightAnchor.constraint(equalToConstant: 34),
            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: AppTheme.Spacing.md),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -AppTheme.Spacing.lg),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: AppTheme.Spacing.lg),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppTheme.Spacing.xs),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -AppTheme.Spacing.lg)
        ])

        return card
    }

    private func infoRow(title: String, value: String) -> UIView {
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

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textColor = AppTheme.Colors.navy
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.numberOfLines = 0

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        return stack
    }

    private func formattedDate() -> String {
        guard let date = task.scheduledDate else {
            return "\(task.time.hour):\(task.time.minute), \(task.time.day)/\(task.time.month)/\(task.time.year)"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm, dd/MM/yyyy"
        return formatter.string(from: date)
    }

    private func formattedDuration() -> String {
        let minutes = task.effectiveDurationMinutes
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes == 0 ? "\(hours) giờ" : "\(hours) giờ \(remainingMinutes) phút"
        }

        return "\(minutes) phút"
    }

    @objc private func showEditTask() {
        let controller = TaskFormViewController(mode: .edit(task))
        controller.onSave = { [weak self] in
            self?.onTaskChanged?()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func confirmCompletedTask() {
        confirmButton.setLoading(true, title: "Xác nhận hoàn thành")
        APIClient.shared.deleteTask(id: task.id) { [weak self] result in
            guard let self = self else { return }
            self.confirmButton.setLoading(false, title: "Xác nhận hoàn thành")

            switch result {
            case .success:
                self.onTaskChanged?()
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                self.statusBanner.show(message: error.localizedDescription)
            }
        }
    }
}
