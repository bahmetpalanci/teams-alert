import SwiftUI

struct WatchListView: View {
    @Bindable var config: AppConfig
    @State private var newName = ""
    @State private var newSound: String?

    private var soundNames: [String] { SoundPlayer.systemSoundNames }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watch List")
                .font(.headline)

            // Add new entry
            HStack {
                TextField("Contact name...", text: $newName)
                    .textFieldStyle(.roundedBorder)

                Picker("Sound", selection: $newSound) {
                    Text("Default").tag(nil as String?)
                    ForEach(soundNames, id: \.self) { name in
                        Text(name).tag(name as String?)
                    }
                }
                .frame(width: 120)

                Button {
                    addEntry()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if config.watchList.isEmpty {
                Text("No contacts added yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(Array(config.watchList.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { entry.enabled },
                                set: { config.watchList[index].enabled = $0 }
                            ))
                            .labelsHidden()
                            .toggleStyle(.checkbox)

                            VStack(alignment: .leading) {
                                Text(entry.name)
                                    .font(.body)
                                if let sound = entry.soundName {
                                    Text(sound)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                SoundPlayer.play(name: entry.soundName ?? config.defaultSoundName)
                            } label: {
                                Image(systemName: "speaker.wave.2")
                            }
                            .buttonStyle(.borderless)

                            Button {
                                config.watchList.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: 100, maxHeight: 250)
            }
        }
        .padding()
    }

    private func addEntry() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        config.watchList.append(WatchEntry(name: trimmed, soundName: newSound))
        newName = ""
        newSound = nil
    }
}
