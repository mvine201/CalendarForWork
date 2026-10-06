import Foundation

struct UserDTO: Codable {
    let id: String
    let username: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case email
    }
}

struct AuthResponse: Codable {
    let user: UserDTO
    let token: String
}

struct UserResponse: Codable {
    let user: UserDTO
}

struct APIMessageResponse: Codable {
    let message: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct TaskTimeDTO: Codable, Equatable {
    var hour: Int
    var minute: Int
    var day: Int
    var month: Int
    var year: Int
}

struct TaskDTO: Codable, Equatable {
    let id: String
    var name: String
    var priority: TaskPriority
    var priorityRank: Int
    var description: String
    var time: TaskTimeDTO
    var durationMinutes: Int?
    var dueAt: String
    var status: TaskStatus

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case priority
        case priorityRank
        case description
        case time
        case durationMinutes
        case dueAt
        case status
    }
}

struct TaskListResponse: Codable {
    let tasks: [TaskDTO]
}

struct TaskResponse: Codable {
    let task: TaskDTO
}

struct TaskMutationRequest: Codable {
    var name: String?
    var priority: TaskPriority?
    var description: String?
    var time: TaskTimeDTO?
    var durationMinutes: Int?
    var status: TaskStatus?
}

extension TaskTimeDTO {
    var date: Date? {
        DateComponents(
            calendar: Calendar.current,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date
    }
}

extension TaskDTO {
    var effectiveDurationMinutes: Int {
        max(durationMinutes ?? 60, 1)
    }

    var scheduledDate: Date? {
        time.date
    }

    var completionDate: Date? {
        scheduledDate?.addingTimeInterval(TimeInterval(effectiveDurationMinutes * 60))
    }

    var isCompletedOrOverdue: Bool {
        if status == .done {
            return true
        }

        guard let completionDate = completionDate else {
            return false
        }

        return completionDate <= Date()
    }

    var isCurrentTask: Bool {
        !isCompletedOrOverdue
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low
    case normal
    case high
    case urgent

    var title: String {
        switch self {
        case .low: return "Thấp"
        case .normal: return "Bình thường"
        case .high: return "Cao"
        case .urgent: return "Khẩn cấp"
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case new
    case inProgress = "in_progress"
    case done

    var title: String {
        switch self {
        case .new: return "Mới"
        case .inProgress: return "Đang làm"
        case .done: return "Đã làm"
        }
    }
}
