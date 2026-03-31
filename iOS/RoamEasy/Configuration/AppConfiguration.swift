import Foundation

enum AppConfiguration {
    static var apiBaseURL: String {
        #if DEBUG
        return "https://api.roameasyapp.com"
        #else
        return "https://api.roameasyapp.com"
        #endif
    }
}
