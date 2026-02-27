import SwiftUI

struct MenuBarView: View {
    @Bindable var config: AppConfig
    @Bindable var monitor: MessageMonitor
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Teams Alert")
                    .font(.headline)
                Spacer()
                if monitor.isMonitoring {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("Alerts").tag(0)
                Text("Watch List").tag(1)
                Text("Settings").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case 0:
                alertsTab
            case 1:
                WatchListView(config: config)
            case 2:
                SettingsView(config: config, monitor: monitor)
            default:
                EmptyView()
            }

            Divider()

            // Footer
            HStack {
                Button(monitor.isMonitoring ? "Stop" : "Start") {
                    if monitor.isMonitoring {
                        monitor.stop()
                    } else {
                        monitor.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(monitor.isMonitoring ? .red : .green)
                .controlSize(.small)

                if !monitor.hasAccessibilityPermission {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .help("Accessibility permission not granted")
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 380, height: selectedTab == 0 ? 420 : nil)
        .fixedSize(horizontal: false, vertical: selectedTab != 0)
    }

    private var alertsTab: some View {
        VStack(spacing: 0) {
            if let error = monitor.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .lineLimit(2)
                }
                .padding(8)
                .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal)
                .padding(.top, 4)
            }

            if monitor.alerts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                    Text("No alerts yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let time = monitor.lastEventTime {
                        Text("Last event: \(time.formatted(.dateTime.hour().minute().second()))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    if !monitor.isMonitoring {
                        Text("Press Start to begin monitoring")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    Text("\(monitor.alerts.count) alerts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear") {
                        monitor.clearAlerts()
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                List(monitor.alerts) { alert in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(alert.senderName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(alert.timestamp.formatted(.dateTime.hour().minute()))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if !alert.messagePreview.isEmpty {
                            Text(alert.messagePreview)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }
        }
    }
}
