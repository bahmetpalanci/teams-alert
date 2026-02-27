import AppKit

enum SoundPlayer {
    static func play(name: String?) {
        let soundName = name ?? "Glass"
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        } else {
            NSSound.beep()
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
