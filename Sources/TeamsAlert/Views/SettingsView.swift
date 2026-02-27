import SwiftUI

struct SettingsView: View {
    @Bindable var config: AppConfig
    var monitor: MessageMonitor

    private var soundNames: [String] { SoundPlayer.systemSoundNames }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)

            GroupBox("Sound") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Default sound") {
                        HStack {
                            Picker("", selection: $config.defaultSoundName) {
                                ForEach(soundNames, id: \.self) { name in
                                    Text(name).tag(name)
                                }
                            }
                            .frame(width: 150)
                            .labelsHidden()

                            Button {
                                SoundPlayer.play(name: config.defaultSoundName)
                            } label: {
                                Image(systemName: "speaker.wave.2")
                            }
                        }
                    }

                    Toggle("Alert on all Teams notifications", isOn: $config.alertOnAllIfNoMatch)
                        .font(.caption)

                    Text("When enabled, plays sound for every Teams chat notification, not just watch list matches.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(4)
            }

            GroupBox("Accessibility") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: monitor.hasAccessibilityPermission
                              ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(monitor.hasAccessibilityPermission ? .green : .orange)

                        Text(monitor.hasAccessibilityPermission
                             ? "Accessibility permission granted"
                             : "Accessibility permission needed")
                            .font(.subheadline)
                    }

                    if !monitor.hasAccessibilityPermission {
                        Text("Without Accessibility permission, sender names cannot be read from notification banners. The app will still detect notifications but can't identify who sent them.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Button("Grant Accessibility Permission") {
                            monitor.requestAccessibility()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    Button("Re-check Permission") {
                        monitor.checkAccessibility()
                    }
                    .controlSize(.small)
                }
                .padding(4)
            }

            GroupBox("About") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Teams Alert monitors Microsoft Teams log files for new chat notifications and plays custom sounds for specific contacts.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("Log directory:")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text("~/Library/Group Containers/UBF8T346G9.com.microsoft.teams/")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(4)
            }
        }
        .padding()
    }
}
