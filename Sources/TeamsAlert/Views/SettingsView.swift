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
                                SoundPlayer.playRepeated(
                                    name: config.defaultSoundName,
                                    count: config.repeatCount,
                                    interval: config.repeatInterval,
                                    afterDelay: 0
                                )
                            } label: {
                                Image(systemName: "speaker.wave.2")
                            }
                        }
                    }

                    LabeledContent("Delay") {
                        HStack {
                            Slider(value: $config.alertDelay, in: 1...10, step: 0.5)
                                .frame(width: 140)
                            Text("\(config.alertDelay, specifier: "%.1f")s")
                                .monospacedDigit()
                                .frame(width: 35, alignment: .trailing)
                        }
                    }

                    LabeledContent("Repeat") {
                        HStack {
                            Picker("", selection: $config.repeatCount) {
                                ForEach(1...5, id: \.self) { n in
                                    Text("\(n)x").tag(n)
                                }
                            }
                            .frame(width: 60)
                            .labelsHidden()

                            Text("every")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("", selection: Binding(
                                get: { config.repeatInterval },
                                set: { config.repeatInterval = $0 }
                            )) {
                                Text("0.5s").tag(0.5)
                                Text("1s").tag(1.0)
                                Text("1.5s").tag(1.5)
                                Text("2s").tag(2.0)
                            }
                            .frame(width: 65)
                            .labelsHidden()
                        }
                    }

                    Text("Sound plays \(config.alertDelay, specifier: "%.1f")s after Teams notification, repeats \(config.repeatCount)x.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Divider()

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
