import AppKit

enum SoundPlayer {
    static func play(name: String?) {
        let soundName = name ?? "Sosumi"
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    static func playRepeated(name: String?, count: Int, interval: TimeInterval, afterDelay delay: TimeInterval) {
        let soundName = name ?? "Sosumi"
        let actualCount = max(1, count)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            playSequence(soundName: soundName, remaining: actualCount, interval: interval)
        }
    }

    private static func playSequence(soundName: String, remaining: Int, interval: TimeInterval) {
        guard remaining > 0 else { return }

        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        } else {
            NSSound.beep()
        }

        if remaining > 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                playSequence(soundName: soundName, remaining: remaining - 1, interval: interval)
            }
        }
    }

    static var systemSoundNames: [String] {
        let soundDirs = [
            "/System/Library/Sounds",
            "/Library/Sounds"
        ]
        var names: [String] = []
        let fm = FileManager.default
        for dir in soundDirs {
            if let files = try? fm.contentsOfDirectory(atPath: dir) {
                for file in files {
                    let name = (file as NSString).deletingPathExtension
                    if !names.contains(name) {
                        names.append(name)
                    }
                }
            }
        }
        return names.sorted()
    }
}
