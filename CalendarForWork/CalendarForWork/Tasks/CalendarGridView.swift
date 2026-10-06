import UIKit

protocol CalendarGridViewDelegate: AnyObject {
    func calendarGridView(_ view: CalendarGridView, didSelect task: TaskDTO)
}

enum CalendarDisplayMode {
    case week
    case month
}

final class CalendarGridHeaderView: UIView {
    var visibleDate = Date() {
        didSet { setNeedsDisplay() }
    }

    var displayMode: CalendarDisplayMode = .week {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }

    var availableWidth: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }

    private var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }()

    private let timeColumnWidth: CGFloat = 40
    private let weekHeaderHeight: CGFloat = 48
    private let monthHeaderHeight: CGFloat = 38

    override var intrinsicContentSize: CGSize {
        let height = displayMode == .week ? weekHeaderHeight : monthHeaderHeight
        return CGSize(width: resolvedWidth, height: height)
    }

    private var resolvedWidth: CGFloat {
        availableWidth > 0 ? availableWidth : 320
    }

    private var weekDayWidth: CGFloat {
        (resolvedWidth - timeColumnWidth) / 7
    }

    private var monthDayWidth: CGFloat {
        resolvedWidth / 7
    }

    private var weekDates: [Date] {
        let start = startOfWeek(for: visibleDate)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = AppTheme.Colors.card
        isOpaque = true
    }

    override func draw(_ rect: CGRect) {
        AppTheme.Colors.card.setFill()
        UIBezierPath(rect: rect).fill()

        switch displayMode {
        case .week:
            drawWeekHeader()
        case .month:
            drawMonthHeader()
        }

        AppTheme.Colors.navy.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: bounds.maxY - 3, width: bounds.width, height: 3)).fill()
    }

    private func drawWeekHeader() {
        let paragraph = centeredParagraph()
        let weekdayAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: AppTheme.Colors.textSecondary,
            .paragraphStyle: paragraph
        ]
        let dayAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: AppTheme.Colors.navy,
            .paragraphStyle: paragraph
        ]

        for (index, date) in weekDates.enumerated() {
            let x = timeColumnWidth + CGFloat(index) * weekDayWidth
            let frame = CGRect(x: x, y: 0, width: weekDayWidth, height: weekHeaderHeight)

            if calendar.isDateInToday(date) {
                AppTheme.Colors.amberSoft.setFill()
                UIBezierPath(rect: frame).fill()
            }

            weekdayTitle(for: date).draw(in: CGRect(x: frame.minX, y: 7, width: frame.width, height: 15), withAttributes: weekdayAttributes)
            "\(calendar.component(.day, from: date))".draw(in: CGRect(x: frame.minX, y: 23, width: frame.width, height: 20), withAttributes: dayAttributes)
        }
    }

    private func drawMonthHeader() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: AppTheme.Colors.navy,
            .paragraphStyle: centeredParagraph()
        ]
        let titles = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

        for (index, title) in titles.enumerated() {
            title.draw(
                in: CGRect(x: CGFloat(index) * monthDayWidth, y: 10, width: monthDayWidth, height: 18),
                withAttributes: attributes
            )
        }
    }

    private func centeredParagraph() -> NSMutableParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        return paragraph
    }

    private func startOfWeek(for date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
    }

    private func weekdayIndex(for date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    private func weekdayTitle(for date: Date) -> String {
        switch weekdayIndex(for: date) {
        case 0: return "T2"
        case 1: return "T3"
        case 2: return "T4"
        case 3: return "T5"
        case 4: return "T6"
        case 5: return "T7"
        default: return "CN"
        }
    }
}

final class CalendarGridView: UIView {
    weak var delegate: CalendarGridViewDelegate?

    var visibleDate = Date() {
        didSet { refreshDrawing() }
    }

    var displayMode: CalendarDisplayMode = .week {
        didSet { refreshDrawing() }
    }

    var availableWidth: CGFloat = 0 {
        didSet { refreshDrawing() }
    }

    var tasks: [TaskDTO] = [] {
        didSet { setNeedsDisplay() }
    }

    private var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }()

    private let timeColumnWidth: CGFloat = 40
    private let hourRowHeight: CGFloat = 96
    private let monthRowHeight: CGFloat = 148
    private let orderedWeekHours = Array(5...23) + Array(0...4)
    private var taskFrames: [(task: TaskDTO, frame: CGRect)] = []

    override var intrinsicContentSize: CGSize {
        switch displayMode {
        case .week:
            return CGSize(width: resolvedWidth, height: 24 * hourRowHeight)
        case .month:
            return CGSize(width: resolvedWidth, height: CGFloat(monthRowCount) * monthRowHeight)
        }
    }

    private var resolvedWidth: CGFloat {
        availableWidth > 0 ? availableWidth : 320
    }

    private var weekDayWidth: CGFloat {
        (resolvedWidth - timeColumnWidth) / 7
    }

    private var monthDayWidth: CGFloat {
        resolvedWidth / 7
    }

    private var weekDates: [Date] {
        let start = startOfWeek(for: visibleDate)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var monthRowCount: Int {
        let firstDate = firstDateOfMonth()
        let leadingDays = weekdayIndex(for: firstDate)
        let days = calendar.range(of: .day, in: .month, for: visibleDate)?.count ?? 30
        return Int(ceil(Double(leadingDays + days) / 7.0))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = AppTheme.Colors.card
        isOpaque = true
    }

    private func refreshDrawing() {
        invalidateIntrinsicContentSize()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        AppTheme.Colors.card.setFill()
        context.fill(rect)
        taskFrames.removeAll()

        switch displayMode {
        case .week:
            drawWeek(context)
        case .month:
            drawMonth(context)
        }
    }

    private func drawWeek(_ context: CGContext) {
        drawWeekHourLabels()
        drawWeekGrid(context)
        drawWeekTasks()
    }

    private func drawWeekHourLabels() {
        let hourAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: AppTheme.Colors.textSecondary,
            .paragraphStyle: centeredParagraph()
        ]

        for (index, hour) in orderedWeekHours.enumerated() {
            let y = CGFloat(index) * hourRowHeight
            "\(String(format: "%02d", hour)):00".draw(
                in: CGRect(x: 0, y: y + 8, width: timeColumnWidth - 4, height: 18),
                withAttributes: hourAttributes
            )
        }
    }

    private func drawWeekGrid(_ context: CGContext) {
        for (index, date) in weekDates.enumerated() where calendar.isDateInToday(date) {
            let x = timeColumnWidth + CGFloat(index) * weekDayWidth
            AppTheme.Colors.amberSoft.setFill()
            UIBezierPath(rect: CGRect(x: x, y: 0, width: weekDayWidth, height: bounds.height)).fill()
        }

        context.setStrokeColor(AppTheme.Colors.border.cgColor)
        context.setLineWidth(0.75)

        for day in 0...7 {
            let x = timeColumnWidth + CGFloat(day) * weekDayWidth
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: bounds.height))
        }

        for hour in 0...24 {
            let y = CGFloat(hour) * hourRowHeight
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: bounds.width, y: y))
        }

        context.strokePath()
        drawTopAccent()
    }

    private func drawWeekTasks() {
        let titleAttributes = taskTitleAttributes(fontSize: 8.6)
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.86)
        ]

        for task in tasks {
            guard let dayIndex = weekDates.firstIndex(where: { matches(task, date: $0) }) else { continue }

            let x = timeColumnWidth + CGFloat(dayIndex) * weekDayWidth + 4
            let minuteOffset = CGFloat(task.time.minute) / 60 * hourRowHeight
            let hourIndex = orderedWeekHours.firstIndex(of: task.time.hour) ?? task.time.hour
            let y = CGFloat(hourIndex) * hourRowHeight + minuteOffset + 4
            let durationHeight = max(CGFloat(task.effectiveDurationMinutes) / 60 * hourRowHeight - 8, 42)
            let frame = CGRect(x: x, y: y, width: weekDayWidth - 8, height: durationHeight)

            drawTaskPill(task, in: frame, titleAttributes: titleAttributes, statusAttributes: statusAttributes)
        }
    }

    private func drawMonth(_ context: CGContext) {
        drawMonthGrid(context)
        drawMonthTasks()
    }

    private func drawMonthGrid(_ context: CGContext) {
        context.setStrokeColor(AppTheme.Colors.border.cgColor)
        context.setLineWidth(0.75)

        for column in 0...7 {
            let x = CGFloat(column) * monthDayWidth
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: bounds.height))
        }

        for row in 0...monthRowCount {
            let y = CGFloat(row) * monthRowHeight
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: bounds.width, y: y))
        }

        context.strokePath()
        drawTopAccent()
    }

    private func drawMonthTasks() {
        let firstDate = firstDateOfMonth()
        let leadingDays = weekdayIndex(for: firstDate)
        let days = calendar.range(of: .day, in: .month, for: visibleDate)?.count ?? 30

        let dayAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: AppTheme.Colors.navy
        ]
        let taskAttributes = taskTitleAttributes(fontSize: 8.5)

        for day in 1...days {
            let cellIndex = leadingDays + day - 1
            let row = cellIndex / 7
            let column = cellIndex % 7
            let cellFrame = CGRect(
                x: CGFloat(column) * monthDayWidth,
                y: CGFloat(row) * monthRowHeight,
                width: monthDayWidth,
                height: monthRowHeight
            )

            if isToday(day: day) {
                AppTheme.Colors.amberSoft.setFill()
                UIBezierPath(rect: cellFrame).fill()
            }

            "\(day)".draw(in: cellFrame.insetBy(dx: 7, dy: 7), withAttributes: dayAttributes)

            let allDayTasks = tasks
                .filter { isTaskInVisibleMonth($0) && $0.time.day == day }
                .sorted { $0.time.hour == $1.time.hour ? $0.time.minute < $1.time.minute : $0.time.hour < $1.time.hour }
            let visibleDayTasks = Array(allDayTasks.prefix(3))
            let taskCount = max(visibleDayTasks.count, 1)
            let availableTaskHeight = cellFrame.height - 36
            let taskHeight = min(CGFloat(visibleDayTasks.count == 1 ? 72 : 42), (availableTaskHeight - CGFloat(taskCount - 1) * 6) / CGFloat(taskCount))

            for (index, task) in visibleDayTasks.enumerated() {
                let frame = CGRect(
                    x: cellFrame.minX + 6,
                    y: cellFrame.minY + 30 + CGFloat(index) * (taskHeight + 6),
                    width: cellFrame.width - 12,
                    height: taskHeight
                )
                taskColor(task).setFill()
                UIBezierPath(roundedRect: frame, cornerRadius: 5).fill()
                drawMultiline("\(String(format: "%02d", task.time.hour)):\(String(format: "%02d", task.time.minute)) · \(formattedDuration(task)) \(task.name)", in: frame.insetBy(dx: 5, dy: 4), attributes: taskAttributes)
                taskFrames.append((task, frame))
            }

            if allDayTasks.count > visibleDayTasks.count {
                let moreFrame = CGRect(x: cellFrame.minX + 6, y: cellFrame.maxY - 22, width: cellFrame.width - 12, height: 16)
                let moreAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .bold),
                    .foregroundColor: AppTheme.Colors.navy
                ]
                "+\(allDayTasks.count - visibleDayTasks.count) công việc".draw(in: moreFrame, withAttributes: moreAttributes)
            }
        }
    }

    private func drawTaskPill(
        _ task: TaskDTO,
        in frame: CGRect,
        titleAttributes: [NSAttributedString.Key: Any],
        statusAttributes: [NSAttributedString.Key: Any]
    ) {
        taskColor(task).setFill()
        UIBezierPath(roundedRect: frame, cornerRadius: AppTheme.Radius.small).fill()
        drawMultiline(task.name, in: CGRect(x: frame.minX + 5, y: frame.minY + 6, width: frame.width - 10, height: frame.height - 24), attributes: titleAttributes)
        let statusTitle = task.isCompletedOrOverdue ? TaskStatus.done.title : task.status.title
        statusTitle.draw(in: CGRect(x: frame.minX + 5, y: frame.maxY - 18, width: frame.width - 10, height: 13), withAttributes: statusAttributes)
        taskFrames.append((task, frame))
    }

    private func taskTitleAttributes(fontSize: CGFloat) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byCharWrapping
        paragraph.alignment = .left
        paragraph.lineSpacing = 1

        return [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
    }

    private func drawMultiline(_ text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        (text as NSString).draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
    }

    private func drawTopAccent() {
        AppTheme.Colors.navy.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: bounds.width, height: 3)).fill()
    }

    private func centeredParagraph() -> NSMutableParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        return paragraph
    }

    private func startOfWeek(for date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
    }

    private func firstDateOfMonth() -> Date {
        let components = calendar.dateComponents([.year, .month], from: visibleDate)
        return calendar.date(from: components) ?? visibleDate
    }

    private func weekdayIndex(for date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    private func weekdayTitle(for date: Date) -> String {
        switch weekdayIndex(for: date) {
        case 0: return "T2"
        case 1: return "T3"
        case 2: return "T4"
        case 3: return "T5"
        case 4: return "T6"
        case 5: return "T7"
        default: return "CN"
        }
    }

    private func matches(_ task: TaskDTO, date: Date) -> Bool {
        let components = calendar.dateComponents([.day, .month, .year], from: date)
        return task.time.day == components.day && task.time.month == components.month && task.time.year == components.year
    }

    private func isTaskInVisibleMonth(_ task: TaskDTO) -> Bool {
        let components = calendar.dateComponents([.month, .year], from: visibleDate)
        return task.time.month == components.month && task.time.year == components.year
    }

    private func isToday(day: Int) -> Bool {
        let today = calendar.dateComponents([.day, .month, .year], from: Date())
        let visible = calendar.dateComponents([.month, .year], from: visibleDate)
        return today.day == day && today.month == visible.month && today.year == visible.year
    }

    private func priorityColor(_ priority: TaskPriority) -> UIColor {
        switch priority {
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

    private func taskColor(_ task: TaskDTO) -> UIColor {
        if task.isCompletedOrOverdue {
            return AppTheme.Colors.success
        }

        return priorityColor(task.priority)
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

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if let item = taskFrames.first(where: { $0.frame.contains(point) }) {
            delegate?.calendarGridView(self, didSelect: item.task)
        }
    }
}
