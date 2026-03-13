import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("appTheme") var themeRaw: String = AppTheme.green.rawValue

    var theme: AppTheme {
        AppTheme(rawValue: themeRaw) ?? .green
    }
}
