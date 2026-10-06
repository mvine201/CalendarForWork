import UIKit

final class TaskListCell: UICollectionViewCell {
    static let reuseIdentifier = "TaskListCell"

    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let priorityView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        contentView.backgroundColor = AppTheme.Colors.card
        contentView.layer.cornerRadius = AppTheme.Radius.medium
        contentView.layer.borderColor = AppTheme.Colors.border.cgColor
        contentView.layer.borderWidth = 1

        priorityView.layer.cornerRadius = 4
        priorityView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = AppTheme.Colors.navy
        titleLabel.numberOfLines = 2

        metaLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        metaLabel.textColor = AppTheme.Colors.textSecondary
        metaLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [titleLabel, metaLabel])
        stack.axis = .vertical
        stack.spacing = AppTheme.Spacing.xs
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(priorityView)
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            priorityView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppTheme.Spacing.md),
            priorityView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppTheme.Spacing.md),
            priorityView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppTheme.Spacing.md),
            priorityView.widthAnchor.constraint(equalToConstant: 6),
            stack.leadingAnchor.constraint(equalTo: priorityView.trailingAnchor, constant: AppTheme.Spacing.md),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppTheme.Spacing.md),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with task: TaskDTO) {
        titleLabel.text = task.name
        metaLabel.text = "\(task.priority.title) · \(task.status.title) · \(formattedDate(task)) · \(formattedDuration(task))"
        priorityView.backgroundColor = color(for: task)
    }

    private func formattedDate(_ task: TaskDTO) -> String {
        guard let date = task.scheduledDate else {
            return "\(task.time.day)/\(task.time.month)/\(task.time.year)"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm, dd/MM/yyyy"
        return formatter.string(from: date)
    }

    private func formattedDuration(_ task: TaskDTO) -> String {
        let minutes = task.effectiveDurationMinutes
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes == 0 ? "\(hours) giờ" : "\(hours) giờ \(remainingMinutes) phút"
        }

        return "\(minutes) phút"
    }

    private func color(for task: TaskDTO) -> UIColor {
        if task.isCompletedOrOverdue {
            return AppTheme.Colors.success
        }

        switch task.priority {
        case .low:
            return UIColor(hex: "#5B6B7A")
        case .normal:
            return AppTheme.Colors.navyLight
        case .high:
            return UIColor(hex: "#C17700")
        case .urgent:
            return AppTheme.Colors.danger
        }
    }
}
