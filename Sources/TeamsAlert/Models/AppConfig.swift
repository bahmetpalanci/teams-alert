import Foundation
import SwiftUI

@Observable
final class AppConfig {
    static let shared = AppConfig()

    var defaultSoundName: String {
        didSet { save() }
    }
    var watchList: [WatchEntry] {
        didSet { save() }
    }
    var alertOnAllIfNoMatch: Bool {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard

    private init() {
        defaultSoundName = defaults.string(forKey: "defaultSoundName") ?? "Glass"
        alertOnAllIfNoMatch = defaults.bool(forKey: "alertOnAllIfNoMatch")
        if let data = defaults.data(forKey: "watchList"),
           let list = try? JSONDecoder().decode([WatchEntry].self, from: data) {
            watchList = list
        } else {
            watchList = []
        }
    }

    private func save() {
        defaults.set(defaultSoundName, forKey: "defaultSoundName")
        defaults.set(alertOnAllIfNoMatch, forKey: "alertOnAllIfNoMatch")
        if let data = try? JSONEncoder().encode(watchList) {
            defaults.set(data, forKey: "watchList")
        }
    }
}
