import UIKit

final class TaskFormViewController: UIViewController {
    enum Mode {
        case create
        case edit(TaskDTO)
    }

    var onSave: (() -> Void)?

    private let mode: Mode
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let statusBanner = StatusBannerView()
    private let nameField = FormTextField(placeholder: "Tên công việc", systemImageName: "briefcase")
    private let descriptionView = UITextView()
    private let datePicker = UIDatePicker()
    private let durationField = FormTextField(placeholder: "Thời lượng làm việc (phút)", systemImageName: "timer")
    private let priorityControl = UISegmentedControl(items: TaskPriority.allCases.map { $0.title })
    private let statusControl = UISegmentedControl(items: TaskStatus.allCases.map { $0.title })
    private let submitButton = PrimaryButton(type: .system)
    private let deleteButton = UIButton(type: .system)

    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.mode = .create
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.Colors.background
        title = isCompletedTask ? "Thông tin" : (isEditingTask ? "Chỉnh sửa" : "Thêm công việc")
        configureLayout()
        configureValues()
        configureActions()
        configureKeyboard()
    }

    private var isEditingTask: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var isCompletedTask: Bool {
        if case .edit(let task) = mode {
            return task.isCompletedOrOverdue
        }
        return false
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

        descriptionView.font = .systemFont(ofSize: 16)
        descriptionView.textColor = AppTheme.Colors.textPrimary
        descriptionView.backgroundColor = AppTheme.Colors.card
        descriptionView.tintColor = AppTheme.Colors.amber
        descriptionView.layer.borderColor = AppTheme.Colors.border.cgColor
        descriptionView.layer.borderWidth = 1
        descriptionView.layer.cornerRadius = AppTheme.Radius.small
        descriptionView.heightAnchor.constraint(equalToConstant: 130).isActive = true

        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .inline
        datePicker.tintColor = AppTheme.Colors.amber
        datePicker.minimumDate = isCompletedTask ? nil : Date()
        durationField.keyboardType = .numberPad

        styleSegmented(priorityControl)
        styleSegmented(statusControl)

        submitButton.setTitle(isEditingTask ? "Lưu thay đổi" : "Thêm công việc", for: .normal)
        submitButton.isHidden = isCompletedTask
        deleteButton.setTitle(isCompletedTask ? "Xác nhận hoàn thành" : "Xóa công việc", for: .normal)
        deleteButton.setTitleColor(isCompletedTask ? AppTheme.Colors.success : AppTheme.Colors.danger, for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        deleteButton.isHidden = !isEditingTask

        contentStack.addArrangedSubview(makeHeader())
        contentStack.addArrangedSubview(statusBanner)
        contentStack.addArrangedSubview(makeSection(title: "Thông tin", views: [nameField, descriptionView]))
        contentStack.addArrangedSubview(makeSection(title: "Mức ưu tiên", views: [priorityControl]))
        contentStack.addArrangedSubview(makeSection(title: "Trạng thái", views: [statusControl]))
        contentStack.addArrangedSubview(makeSection(title: "Thời gian", views: [datePicker, durationField]))
        contentStack.addArrangedSubview(submitButton)
        contentStack.addArrangedSubview(deleteButton)

        if isCompletedTask {
            applyCompletedReadOnlyState()
        }
    }

    private func makeHeader() -> UIView {
        let card = UIView()
        card.backgroundColor = AppTheme.Colors.navy
        card.layer.cornerRadius = AppTheme.Radius.medium

        let icon = UIImageView(image: UIImage(systemName: isCompletedTask ? "checkmark.seal.fill" : (isEditingTask ? "square.and.pencil" : "calendar.badge.plus")))
        icon.tintColor = isCompletedTask ? AppTheme.Colors.success : AppTheme.Colors.amber
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = isCompletedTask ? "Công việc đã hoàn thành" : (isEditingTask ? "Cập nhật công việc" : "Lên lịch công việc")
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 21, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = isCompletedTask ? "Công việc này đã qua mốc thời gian. Xác nhận hoàn thành để xóa khỏi lịch." : "Chọn ngày giờ, mức ưu tiên và trạng thái để sắp xếp trên lịch."
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.74)
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.numberOfLines = 0
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

    private func makeSection(title: String, views: [UIView]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppTheme.Spacing.sm
        stack.backgroundColor = AppTheme.Colors.card
        stack.layer.cornerRadius = AppTheme.Radius.medium
        stack.layoutMargins = UIEdgeInsets(top: AppTheme.Spacing.md, left: AppTheme.Spacing.md, bottom: AppTheme.Spacing.md, right: AppTheme.Spacing.md)
        stack.isLayoutMarginsRelativeArrangement = true

        let label = UILabel()
        label.text = title
        label.textColor = AppTheme.Colors.navy
        label.font = .systemFont(ofSize: 15, weight: .bold)
        stack.addArrangedSubview(label)
        views.forEach { stack.addArrangedSubview($0) }

        return stack
    }

    private func styleSegmented(_ control: UISegmentedControl) {
        control.selectedSegmentTintColor = AppTheme.Colors.amber
        control.backgroundColor = AppTheme.Colors.background
        control.setTitleTextAttributes([.foregroundColor: AppTheme.Colors.navy], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: AppTheme.Colors.textSecondary], for: .normal)
        control.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    private func configureValues() {
        priorityControl.selectedSegmentIndex = TaskPriority.allCases.firstIndex(of: .normal) ?? 1
        statusControl.selectedSegmentIndex = TaskStatus.allCases.firstIndex(of: .new) ?? 0
        datePicker.date = Date().addingTimeInterval(15 * 60)
        durationField.text = "60"
        descriptionView.text = ""

        if case .edit(let task) = mode {
            nameField.text = task.name
            descriptionView.text = task.description
            priorityControl.selectedSegmentIndex = TaskPriority.allCases.firstIndex(of: task.priority) ?? 1
            statusControl.selectedSegmentIndex = TaskStatus.allCases.firstIndex(of: task.status) ?? 0
            datePicker.date = date(from: task.time) ?? Date()
            durationField.text = "\(task.effectiveDurationMinutes)"
        }
    }

    private func applyCompletedReadOnlyState() {
        nameField.isEnabled = false
        descriptionView.isEditable = false
        descriptionView.textColor = AppTheme.Colors.textSecondary
        datePicker.isEnabled = false
        durationField.isEnabled = false
        priorityControl.isEnabled = false
        statusControl.isEnabled = false
        statusBanner.show(message: "Công việc đã tự động chuyển sang hoàn thành.", isError: false)
    }

    private func configureActions() {
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
    }

    private func configureKeyboard() {
        scrollView.keyboardDismissMode = .interactive
        nameField.returnKeyType = .done
        durationField.returnKeyType = .done
        nameField.delegate = self
        durationField.delegate = self
        durationField.inputAccessoryView = doneToolbar()
        descriptionView.inputAccessoryView = doneToolbar()
        enableKeyboardDismissOnTap()
        observeKeyboardForScrollView(scrollView)
    }

    @objc private func handleSubmit() {
        view.endEditing(true)
        statusBanner.hide()

        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            statusBanner.show(message: "Nhập tên công việc.")
            return
        }

        guard datePicker.date > Date() else {
            statusBanner.show(message: "Không thể thêm hoặc chuyển công việc vào thời gian quá khứ.")
            return
        }

        guard let durationText = durationField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let durationMinutes = Int(durationText),
              durationMinutes > 0,
              durationMinutes <= 10080 else {
            statusBanner.show(message: "Thời lượng phải từ 1 phút đến tối đa 7 ngày.")
            return
        }

        let request = TaskMutationRequest(
            name: name,
            priority: TaskPriority.allCases[priorityControl.selectedSegmentIndex],
            description: descriptionView.text.trimmingCharacters(in: .whitespacesAndNewlines),
            time: taskTime(from: datePicker.date),
            durationMinutes: durationMinutes,
            status: TaskStatus.allCases[statusControl.selectedSegmentIndex]
        )

        submitButton.setLoading(true, title: isEditingTask ? "Lưu thay đổi" : "Thêm công việc")

        switch mode {
        case .create:
            APIClient.shared.createTask(request) { [weak self] result in
                self?.handleMutationResult(result)
            }
        case .edit(let task):
            APIClient.shared.updateTask(id: task.id, request: request) { [weak self] result in
                self?.handleMutationResult(result)
            }
        }
    }

    private func handleMutationResult(_ result: Result<TaskResponse, Error>) {
        submitButton.setLoading(false, title: isEditingTask ? "Lưu thay đổi" : "Thêm công việc")

        switch result {
        case .success:
            onSave?()
            navigationController?.popViewController(animated: true)
        case .failure(let error):
            statusBanner.show(message: error.localizedDescription)
        }
    }

    @objc private func handleDelete() {
        guard case .edit(let task) = mode else { return }
        deleteButton.isEnabled = false

        APIClient.shared.deleteTask(id: task.id) { [weak self] result in
            guard let self = self else { return }
            self.deleteButton.isEnabled = true

            switch result {
            case .success:
                self.onSave?()
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                self.statusBanner.show(message: error.localizedDescription)
            }
        }
    }

    private func taskTime(from date: Date) -> TaskTimeDTO {
        let components = Calendar.current.dateComponents([.hour, .minute, .day, .month, .year], from: date)
        return TaskTimeDTO(
            hour: components.hour ?? 0,
            minute: components.minute ?? 0,
            day: components.day ?? 1,
            month: components.month ?? 1,
            year: components.year ?? 2026
        )
    }

    private func date(from time: TaskTimeDTO) -> Date? {
        DateComponents(
            calendar: Calendar.current,
            year: time.year,
            month: time.month,
            day: time.day,
            hour: time.hour,
            minute: time.minute
        ).date
    }
}
