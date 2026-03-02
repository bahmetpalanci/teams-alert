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
    var alertDelay: TimeInterval {
        didSet { save() }
    }
    var repeatCount: Int {
        didSet { save() }
    }
    var repeatInterval: TimeInterval {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard

    private init() {
        defaultSoundName = defaults.string(forKey: "defaultSoundName") ?? "Sosumi"
        alertOnAllIfNoMatch = defaults.bool(forKey: "alertOnAllIfNoMatch")
        alertDelay = defaults.double(forKey: "alertDelay").nonZero ?? 3.0
        repeatCount = defaults.integer(forKey: "repeatCount").nonZero ?? 3
        repeatInterval = defaults.double(forKey: "repeatInterval").nonZero ?? 1.0
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
        defaults.set(alertDelay, forKey: "alertDelay")
        defaults.set(repeatCount, forKey: "repeatCount")
        defaults.set(repeatInterval, forKey: "repeatInterval")
        if let data = try? JSONEncoder().encode(watchList) {
            defaults.set(data, forKey: "watchList")
        }
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
