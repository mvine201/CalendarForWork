import Foundation
import UserNotifications

final class LocalNotificationManager {
    static let shared = LocalNotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let identifierPrefix = "calendarForWork.task."
    private let maxPendingNotifications = 64
    private var hasRequestedAuthorization = false

    private init() {}

    func requestAuthorizationIfNeeded() {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true

        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func syncNotifications(for tasks: [TaskDTO]) {
        requestAuthorizationIfNeeded()

        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            let appRequestIds = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(self.identifierPrefix) }

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: appRequestIds)
            self.scheduleUpcomingNotifications(for: tasks)
        }
    }

    func scheduleNotifications(for task: TaskDTO) {
        requestAuthorizationIfNeeded()
        cancelNotifications(forTaskId: task.id)
        scheduleUpcomingNotifications(for: [task])
    }

    func cancelNotifications(forTaskId taskId: String) {
        let identifiers = notificationIdentifiers(forTaskId: taskId)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func clearAllNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            let appRequestIds = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(self.identifierPrefix) }

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: appRequestIds)
        }
        notificationCenter.removeAllDeliveredNotifications()
    }

    private func scheduleUpcomingNotifications(for tasks: [TaskDTO]) {
        let requests = tasks
            .filter { !$0.isCompletedOrOverdue && $0.status != .done }
            .flatMap(notificationRequests(for:))
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(maxPendingNotifications)

        for request in requests {
            notificationCenter.add(request.notificationRequest)
        }
    }

    private func notificationRequests(for task: TaskDTO) -> [ScheduledNotificationRequest] {
        guard let startDate = task.scheduledDate else { return [] }

        let now = Date()
        let reminderDate = startDate.addingTimeInterval(-15 * 60)
        var requests: [ScheduledNotificationRequest] = []

        if reminderDate > now {
            requests.append(
                makeRequest(
                    task: task,
                    kind: .reminder,
                    fireDate: reminderDate,
                    body: "\(task.name) sẽ bắt đầu sau 15 phút nữa"
                )
            )
        }

        if startDate > now {
            requests.append(
                makeRequest(
                    task: task,
                    kind: .started,
                    fireDate: startDate,
                    body: "\(task.name) đã bắt đầu"
                )
            )
        }

        return requests
    }

    private func makeRequest(
        task: TaskDTO,
        kind: NotificationKind,
        fireDate: Date,
        body: String
    ) -> ScheduledNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Nhắc việc"
        content.body = body
        content.sound = .default
        content.userInfo = ["taskId": task.id]

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(forTaskId: task.id, kind: kind),
            content: content,
            trigger: trigger
        )

        return ScheduledNotificationRequest(fireDate: fireDate, notificationRequest: request)
    }

    private func notificationIdentifiers(forTaskId taskId: String) -> [String] {
        NotificationKind.allCases.map { notificationIdentifier(forTaskId: taskId, kind: $0) }
    }

    private func notificationIdentifier(forTaskId taskId: String, kind: NotificationKind) -> String {
        "\(identifierPrefix)\(taskId).\(kind.rawValue)"
    }
}

private enum NotificationKind: String, CaseIterable {
    case reminder
    case started
}

private struct ScheduledNotificationRequest {
    let fireDate: Date
    let notificationRequest: UNNotificationRequest
}
