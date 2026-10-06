import UIKit

enum AppCoordinator {
    static func makeInitialViewController() -> UIViewController {
        AppTheme.configureNavigationBar()

        if SessionStore.shared.token != nil {
            return makeMainInterface()
        }

        return UINavigationController(rootViewController: LoginViewController())
    }

    static func makeMainInterface() -> UIViewController {
        let tabBarController = UITabBarController()
        tabBarController.tabBar.tintColor = AppTheme.Colors.amber
        tabBarController.tabBar.unselectedItemTintColor = AppTheme.Colors.textSecondary
        tabBarController.tabBar.backgroundColor = AppTheme.Colors.card

        let calendarNavigation = UINavigationController(rootViewController: TaskCalendarViewController())
        calendarNavigation.navigationBar.prefersLargeTitles = true
        calendarNavigation.tabBarItem = UITabBarItem(title: "Lịch", image: UIImage(systemName: "calendar"), selectedImage: UIImage(systemName: "calendar"))

        let taskNavigation = UINavigationController(rootViewController: TaskListViewController())
        taskNavigation.navigationBar.prefersLargeTitles = true
        taskNavigation.tabBarItem = UITabBarItem(title: "Công việc", image: UIImage(systemName: "checklist"), selectedImage: UIImage(systemName: "checklist.checked"))

        let accountNavigation = UINavigationController(rootViewController: AccountViewController())
        accountNavigation.navigationBar.prefersLargeTitles = true
        accountNavigation.tabBarItem = UITabBarItem(title: "Tài khoản", image: UIImage(systemName: "person.crop.circle"), selectedImage: UIImage(systemName: "person.crop.circle.fill"))

        tabBarController.viewControllers = [calendarNavigation, taskNavigation, accountNavigation]
        return tabBarController
    }

    static func setRoot(_ viewController: UIViewController, animated: Bool = true) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        if animated {
            UIView.transition(with: window, duration: 0.28, options: .transitionCrossDissolve) {
                window.rootViewController = viewController
            }
        } else {
            window.rootViewController = viewController
        }
    }

    static func showMainInterface() {
        setRoot(makeMainInterface())
    }

    static func showAuthInterface() {
        setRoot(UINavigationController(rootViewController: LoginViewController()))
    }
}
