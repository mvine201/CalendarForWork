import Foundation

enum APIClientError: LocalizedError {
    case invalidURL
    case noToken
    case emptyResponse
    case server(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Đường dẫn API không hợp lệ."
        case .noToken:
            return "Bạn cần đăng nhập lại."
        case .emptyResponse:
            return "Máy chủ không trả về dữ liệu."
        case .server(let message):
            return message
        case .decoding:
            return "Không đọc được dữ liệu từ máy chủ."
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "https://calendarforwork.onrender.com")!
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func register(_ request: RegisterRequest, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        perform(path: "/api/auth/register", method: "POST", body: request, requiresAuth: false, completion: completion)
    }

    func login(_ request: LoginRequest, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        perform(path: "/api/auth/login", method: "POST", body: request, requiresAuth: false, completion: completion)
    }

    func fetchCurrentUser(completion: @escaping (Result<UserResponse, Error>) -> Void) {
        perform(path: "/api/auth/me", method: "GET", body: Optional<String>.none, requiresAuth: true, completion: completion)
    }

    func fetchTasks(completion: @escaping (Result<TaskListResponse, Error>) -> Void) {
        perform(path: "/api/tasks", method: "GET", body: Optional<String>.none, requiresAuth: true) { result in
            if case .success(let response) = result {
                LocalNotificationManager.shared.syncNotifications(for: response.tasks)
            }
            completion(result)
        }
    }

    func createTask(_ request: TaskMutationRequest, completion: @escaping (Result<TaskResponse, Error>) -> Void) {
        perform(path: "/api/tasks", method: "POST", body: request, requiresAuth: true) { result in
            if case .success(let response) = result {
                LocalNotificationManager.shared.scheduleNotifications(for: response.task)
            }
            completion(result)
        }
    }

    func updateTask(id: String, request: TaskMutationRequest, completion: @escaping (Result<TaskResponse, Error>) -> Void) {
        perform(path: "/api/tasks/\(id)", method: "PATCH", body: request, requiresAuth: true) { result in
            if case .success(let response) = result {
                LocalNotificationManager.shared.scheduleNotifications(for: response.task)
            }
            completion(result)
        }
    }

    func deleteTask(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        performVoid(path: "/api/tasks/\(id)", method: "DELETE", requiresAuth: true) { result in
            if case .success = result {
                LocalNotificationManager.shared.cancelNotifications(forTaskId: id)
            }
            completion(result)
        }
    }

    private func perform<Request: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Request?,
        requiresAuth: Bool,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            completion(.failure(APIClientError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            guard let token = SessionStore.shared.token else {
                completion(.failure(APIClientError.noToken))
                return
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                completion(.failure(error))
                return
            }
        }

        session.dataTask(with: request) { [decoder] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIClientError.emptyResponse))
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(parseServerError(data: data)))
                    return
                }

                guard let data, !data.isEmpty else {
                    completion(.failure(APIClientError.emptyResponse))
                    return
                }

                do {
                    completion(.success(try decoder.decode(Response.self, from: data)))
                } catch {
                    completion(.failure(APIClientError.decoding))
                }
            }
        }.resume()
    }

    private func performVoid(
        path: String,
        method: String,
        requiresAuth: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            completion(.failure(APIClientError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if requiresAuth {
            guard let token = SessionStore.shared.token else {
                completion(.failure(APIClientError.noToken))
                return
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIClientError.emptyResponse))
                    return
                }

                if (200...299).contains(httpResponse.statusCode) {
                    completion(.success(()))
                } else {
                    completion(.failure(parseServerError(data: data)))
                }
            }
        }.resume()
    }
}

private func parseServerError(data: Data?) -> Error {
    guard let data,
          let response = try? JSONDecoder().decode(APIMessageResponse.self, from: data) else {
        return APIClientError.server("Máy chủ báo lỗi. Vui lòng thử lại.")
    }

    return APIClientError.server(response.message)
}
