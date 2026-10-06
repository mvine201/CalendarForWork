import Foundation

final class SessionStore {
    static let shared = SessionStore()

    private let tokenKey = "calendarForWork.authToken"
    private let userEmailKey = "calendarForWork.userEmail"

    var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    var userEmail: String? {
        get { UserDefaults.standard.string(forKey: userEmailKey) }
        set { UserDefaults.standard.set(newValue, forKey: userEmailKey) }
    }

    private init() {}

    func save(token: String, email: String) {
        self.token = token
        self.userEmail = email
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
    }
}
