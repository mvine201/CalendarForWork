import UIKit

enum AppTheme {
    enum Colors {
        static let navy = UIColor(hex: "#0B2545")
        static let navyLight = UIColor(hex: "#163A5F")
        static let amber = UIColor(hex: "#F5A623")
        static let amberSoft = UIColor(hex: "#FFF2D7")
        static let background = UIColor(hex: "#F5F7FA")
        static let card = UIColor.white
        static let textPrimary = UIColor(hex: "#17212B")
        static let textSecondary = UIColor(hex: "#637083")
        static let border = UIColor(hex: "#D9E0EA")
        static let success = UIColor(hex: "#2E7D32")
        static let danger = UIColor(hex: "#B42318")
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
    }

    static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.navy
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 30, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = Colors.amber
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        switch hexString.count {
        case 8:
            red = CGFloat((value & 0xFF000000) >> 24) / 255
            green = CGFloat((value & 0x00FF0000) >> 16) / 255
            blue = CGFloat((value & 0x0000FF00) >> 8) / 255
            alpha = CGFloat(value & 0x000000FF) / 255
        default:
            red = CGFloat((value & 0xFF0000) >> 16) / 255
            green = CGFloat((value & 0x00FF00) >> 8) / 255
            blue = CGFloat(value & 0x0000FF) / 255
            alpha = 1
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
