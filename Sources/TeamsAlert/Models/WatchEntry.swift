import Foundation

struct WatchEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var soundName: String?
    var enabled: Bool = true
}
