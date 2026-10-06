import UIKit

final class TaskCalendarViewController: UIViewController {
    private let periodLabel = UILabel()
    private let summaryLabel = UILabel()
    private let viewModeControl = UISegmentedControl(items: ["Tuần", "Tháng"])
    private let statusBanner = StatusBannerView()
    private let scrollView = UIScrollView()
    private let gridView = CalendarGridView()
    private var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }()
    private var gridWidthConstraint: NSLayoutConstraint?
    private var gridHeightConstraint: NSLayoutConstraint?

    private var visibleDate = Date()
    private var displayMode: CalendarDisplayMode = .week
    private var tasks: [TaskDTO] = []
    private var autoRefreshTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lịch"
        view.backgroundColor = AppTheme.Colors.background
        configureNavigation()
        configureLayout()
        updateHeaderAndGrid()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
        startAutoRefresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoRefresh()
    }

    deinit {
        stopAutoRefresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGridSize()
    }

    private func configureNavigation() {
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
    }

    private func configureLayout() {
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = AppTheme.Spacing.md
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.md),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.md),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.md),
            contentStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -AppTheme.Spacing.md)
        ])

        contentStack.addArrangedSubview(makeHeaderCard())
        contentStack.addArrangedSubview(statusBanner)
        contentStack.addArrangedSubview(scrollView)

        scrollView.backgroundColor = AppTheme.Colors.card
        scrollView.layer.cornerRadius = AppTheme.Radius.medium
        scrollView.layer.borderColor = AppTheme.Colors.border.cgColor
        scrollView.layer.borderWidth = 1
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceHorizontal = false

        gridView.visibleDate = visibleDate
        gridView.displayMode = displayMode
        gridView.delegate = self
        gridView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridView)

        let gridSize = gridView.intrinsicContentSize
        gridWidthConstraint = gridView.widthAnchor.constraint(equalToConstant: gridSize.width)
        gridHeightConstraint = gridView.heightAnchor.constraint(equalToConstant: gridSize.height)

        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            gridWidthConstraint!,
            gridHeightConstraint!
        ])
    }

    private func makeHeaderCard() -> UIView {
        let card = UIView()
        card.backgroundColor = AppTheme.Colors.navy
        card.layer.cornerRadius = AppTheme.Radius.medium

        let previousButton = UIButton(type: .system)
        previousButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        previousButton.tintColor = AppTheme.Colors.amber
        previousButton.addTarget(self, action: #selector(showPreviousPeriod), for: .touchUpInside)

        let nextButton = UIButton(type: .system)
        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextButton.tintColor = AppTheme.Colors.amber
        nextButton.addTarget(self, action: #selector(showNextPeriod), for: .touchUpInside)

        periodLabel.textColor = .white
        periodLabel.font = .systemFont(ofSize: 21, weight: .bold)
        periodLabel.adjustsFontSizeToFitWidth = true
        periodLabel.minimumScaleFactor = 0.78

        summaryLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        summaryLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        let labelStack = UIStackView(arrangedSubviews: [periodLabel, summaryLabel])
        labelStack.axis = .vertical
        labelStack.spacing = AppTheme.Spacing.xs

        let row = UIStackView(arrangedSubviews: [previousButton, labelStack, nextButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = AppTheme.Spacing.sm

        viewModeControl.selectedSegmentIndex = 0
        viewModeControl.selectedSegmentTintColor = AppTheme.Colors.amber
        viewModeControl.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        viewModeControl.setTitleTextAttributes([.foregroundColor: AppTheme.Colors.navy], for: .selected)
        viewModeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        viewModeControl.addTarget(self, action: #selector(changeDisplayMode), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [row, viewModeControl])
        stack.axis = .vertical
        stack.spacing = AppTheme.Spacing.md
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            previousButton.widthAnchor.constraint(equalToConstant: 42),
            nextButton.widthAnchor.constraint(equalToConstant: 42),
            viewModeControl.heightAnchor.constraint(equalToConstant: 36),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: AppTheme.Spacing.md),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: AppTheme.Spacing.sm),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -AppTheme.Spacing.sm),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -AppTheme.Spacing.md)
        ])

        return card
    }

    private func updateHeaderAndGrid() {
        gridView.visibleDate = visibleDate
        gridView.displayMode = displayMode
        gridView.tasks = tasks

        switch displayMode {
        case .week:
            periodLabel.text = weekTitle()
            summaryLabel.text = "\(visibleTasksCount()) công việc trong tuần"
        case .month:
            periodLabel.text = monthTitle()
            summaryLabel.text = "\(visibleTasksCount()) công việc trong tháng"
        }

        updateGridSize()
    }

    private func updateGridSize() {
        let availableWidth = scrollView.bounds.width > 0 ? scrollView.bounds.width : 320
        gridView.availableWidth = availableWidth
        gridWidthConstraint?.constant = gridView.intrinsicContentSize.width
        gridHeightConstraint?.constant = gridView.intrinsicContentSize.height
        gridView.setNeedsDisplay()
    }

    private func visibleTasksCount() -> Int {
        switch displayMode {
        case .week:
            let weekDates = datesInCurrentWeek()
            return tasks.filter { task in
                weekDates.contains { date in
                    let components = calendar.dateComponents([.day, .month, .year], from: date)
                    return task.time.day == components.day && task.time.month == components.month && task.time.year == components.year
                }
            }.count
        case .month:
            let components = calendar.dateComponents([.month, .year], from: visibleDate)
            return tasks.filter { $0.time.month == components.month && $0.time.year == components.year }.count
        }
    }

    private func weekTitle() -> String {
        let dates = datesInCurrentWeek()
        guard let first = dates.first, let last = dates.last else { return "Tuần này" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM"
        let year = calendar.component(.year, from: visibleDate)
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))/\(year)"
    }

    private func monthTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: visibleDate).capitalized
    }

    private func datesInCurrentWeek() -> [Date] {
        let start = startOfWeek(for: visibleDate)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func startOfWeek(for date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
    }

    private func loadTasks() {
        statusBanner.hide()
        APIClient.shared.fetchTasks { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                self.tasks = response.tasks
                self.updateHeaderAndGrid()
            case .failure(let error):
                self.statusBanner.show(message: error.localizedDescription)
            }
        }
    }

    private func startAutoRefresh() {
        stopAutoRefresh()
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.loadTasks()
        }
    }

    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }

    @objc private func showPreviousPeriod() {
        let component: Calendar.Component = displayMode == .week ? .weekOfYear : .month
        visibleDate = calendar.date(byAdding: component, value: -1, to: visibleDate) ?? visibleDate
        updateHeaderAndGrid()
    }

    @objc private func showNextPeriod() {
        let component: Calendar.Component = displayMode == .week ? .weekOfYear : .month
        visibleDate = calendar.date(byAdding: component, value: 1, to: visibleDate) ?? visibleDate
        updateHeaderAndGrid()
    }

    @objc private func changeDisplayMode() {
        displayMode = viewModeControl.selectedSegmentIndex == 0 ? .week : .month
        updateHeaderAndGrid()
    }

}

extension TaskCalendarViewController: CalendarGridViewDelegate {
    func calendarGridView(_ view: CalendarGridView, didSelect task: TaskDTO) {
        let controller = TaskDetailViewController(task: task, allowsEditing: false)
        controller.onTaskChanged = { [weak self] in self?.loadTasks() }
        navigationController?.pushViewController(controller, animated: true)
    }
}
