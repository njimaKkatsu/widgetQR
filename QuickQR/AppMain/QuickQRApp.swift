import SwiftUI

// MARK: メインアプリ構造
@main
struct QuickQRApp: App {
    @AppStorage("userTheme") private var userTheme: Int = 0

    init() {
        if let theme = AppTheme(rawValue: userTheme) {
            applyTheme(theme)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

enum AppTheme: Int {
    case system = 0
    case light
    case dark
}

