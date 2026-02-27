import SwiftUI

@main
struct TeamsAlertApp: App {
    @State private var config = AppConfig.shared
    @State private var monitor = MessageMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(config: config, monitor: monitor)
        } label: {
            Image(systemName: monitor.alerts.isEmpty ? "bell" : "bell.badge")
        }
        .menuBarExtraStyle(.window)
    }
}
