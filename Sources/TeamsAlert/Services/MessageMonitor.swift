import Foundation
import SwiftUI
import ApplicationServices

struct AlertEvent: Identifiable {
    let id = UUID()
    let senderName: String
    let messagePreview: String
    let timestamp: Date
    let soundName: String?
}

@Observable
@MainActor
final class MessageMonitor {
    var isMonitoring = false
    var alerts: [AlertEvent] = []
    var lastError: String?
    var lastEventTime: Date?
    var hasAccessibilityPermission = false

    private var monitorTask: Task<Void, Never>?
    private var fileHandle: FileHandle?
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var currentLogPath: String?
    private var lastFileSize: UInt64 = 0
    private var seenNotificationIds = Set<String>()

    private let teamsLogsDir = NSHomeDirectory()
        + "/Library/Group Containers/UBF8T346G9.com.microsoft.teams"
        + "/Library/Application Support/Logs"

    private var config: AppConfig { AppConfig.shared }

    func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastError = nil

        checkAccessibility()

        monitorTask = Task { [weak self] in
            guard let self else { return }
            await self.startLogWatching()
        }
    }

    func stop() {
        monitorTask?.cancel()
        monitorTask = nil
        stopFileWatcher()
        isMonitoring = false
    }

    func clearAlerts() {
        alerts.removeAll()
    }

    func checkAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        // Re-check after a delay
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { checkAccessibility() }
        }
    }

    // MARK: - Log File Watching

    private func startLogWatching() async {
        while !Task.isCancelled {
            guard let logPath = findLatestTeamsLog() else {
                lastError = "Teams log directory not found. Is Teams running?"
                try? await Task.sleep(for: .seconds(10))
                continue
            }

            if logPath != currentLogPath {
                stopFileWatcher()
                currentLogPath = logPath
                startFileWatcher(path: logPath)
            }

            try? await Task.sleep(for: .seconds(5))
        }
    }

    private func findLatestTeamsLog() -> String? {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: teamsLogsDir) else { return nil }

        let msTeamsLogs = files
            .filter { $0.hasPrefix("MSTeams_") && $0.hasSuffix(".log") }
            .sorted()

        guard let latest = msTeamsLogs.last else { return nil }
        return teamsLogsDir + "/" + latest
    }

    private func startFileWatcher(path: String) {
        guard let handle = FileHandle(forReadingAtPath: path) else {
            lastError = "Cannot open log file"
            return
        }
        fileHandle = handle

        // Seek to end - only process new entries
        handle.seekToEndOfFile()
        lastFileSize = handle.offsetInFile

        let fd = handle.fileDescriptor
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: .global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            self?.processNewLogLines()
        }

        source.setCancelHandler { [weak self] in
            self?.fileHandle?.closeFile()
            self?.fileHandle = nil
        }

        dispatchSource = source
        source.resume()
        lastError = nil
    }

    private func stopFileWatcher() {
        dispatchSource?.cancel()
        dispatchSource = nil
        currentLogPath = nil
    }

    private func processNewLogLines() {
        guard let handle = fileHandle else { return }

        let newData = handle.readDataToEndOfFile()
        guard !newData.isEmpty, let text = String(data: newData, encoding: .utf8) else { return }

        let lines = text.components(separatedBy: "\n")
        for line in lines {
            // Chat messages go through UNUserNotificationCenter
            if line.contains("posted to UNUserNotificationCenter") {
                if let uuid = extractUUID(from: line), !seenNotificationIds.contains(uuid) {
                    seenNotificationIds.insert(uuid)
                    if seenNotificationIds.count > 200 {
                        seenNotificationIds = Set(seenNotificationIds.suffix(100))
                    }
                    handleChatNotification(uuid: uuid)
                }
            }
            // Calls/meetings go through custom notification center
            else if line.contains("TeamsNotificationCenterService: posting notification") {
                if let uuid = extractUUID(from: line), !seenNotificationIds.contains(uuid) {
                    seenNotificationIds.insert(uuid)
                    if seenNotificationIds.count > 200 {
                        seenNotificationIds = Set(seenNotificationIds.suffix(100))
                    }
                    // Skip calls - we only care about chat messages
                }
            }
        }
    }

    private func extractUUID(from line: String) -> String? {
        let pattern = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
        guard let range = line.range(of: pattern, options: .regularExpression) else { return nil }
        return String(line[range])
    }

    // MARK: - Notification Handling

    private func handleChatNotification(uuid: String) {
        // Small delay to let the notification banner appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            var senderName = "Teams"
            var messagePreview = ""

            // Try to read notification content via Accessibility
            if self.hasAccessibilityPermission {
                if let content = self.readNotificationBannerContent() {
                    senderName = content.title
                    messagePreview = content.body
                }
            }

            self.processAlert(senderName: senderName, messagePreview: messagePreview)
        }
    }

    private func processAlert(senderName: String, messagePreview: String) {
        let enabledEntries = config.watchList.filter(\.enabled)

        if enabledEntries.isEmpty && config.alertOnAllIfNoMatch {
            addAlert(senderName: senderName, messagePreview: messagePreview, soundName: nil)
            return
        }

        if let match = enabledEntries.first(where: { matches(sender: senderName, entry: $0) }) {
            addAlert(senderName: senderName, messagePreview: messagePreview, soundName: match.soundName)
        } else if config.alertOnAllIfNoMatch {
            addAlert(senderName: senderName, messagePreview: messagePreview, soundName: nil)
        }

        lastEventTime = Date()
    }

    private func addAlert(senderName: String, messagePreview: String, soundName: String?) {
        let alert = AlertEvent(
            senderName: senderName,
            messagePreview: messagePreview,
            timestamp: Date(),
            soundName: soundName
        )
        alerts.insert(alert, at: 0)
        if alerts.count > 50 { alerts.removeLast() }

        SoundPlayer.playRepeated(
            name: soundName ?? config.defaultSoundName,
            count: config.repeatCount,
            interval: config.repeatInterval,
            afterDelay: config.alertDelay
        )
    }

    private func matches(sender: String, entry: WatchEntry) -> Bool {
        let senderLower = sender.lowercased()
        let entryLower = entry.name.lowercased()
        return senderLower.contains(entryLower) || entryLower.contains(senderLower)
    }

    // MARK: - Accessibility API

    private func readNotificationBannerContent() -> (title: String, body: String)? {
        // Find Notification Center or Teams notification process
        let apps = NSWorkspace.shared.runningApplications

        // Try macOS Notification Center first (for UNUserNotification)
        if let ncApp = apps.first(where: { $0.bundleIdentifier == "com.apple.NotificationCenter" }) {
            if let result = readAXContent(pid: ncApp.processIdentifier) {
                return result
            }
        }

        // Try Teams notification center (for custom notifications)
        if let teamsNC = apps.first(where: {
            $0.bundleIdentifier == "com.microsoft.teams2.notificationcenter"
        }) {
            if let result = readAXContent(pid: teamsNC.processIdentifier) {
                return result
            }
        }

        return nil
    }

    private func readAXContent(pid: pid_t) -> (title: String, body: String)? {
        let appElement = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else { return nil }

        for window in windows {
            if let result = findNotificationText(in: window) {
                return result
            }
        }
        return nil
    }

    private func findNotificationText(in element: AXUIElement) -> (title: String, body: String)? {
        // Try to get title and description from this element
        var titleRef: CFTypeRef?
        var descRef: CFTypeRef?
        var roleRef: CFTypeRef?

        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)

        // Look for static text elements that might contain notification content
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {

            // Leaf element - check if it has a value
            if let title = titleRef as? String, !title.isEmpty {
                let desc = descRef as? String ?? ""
                return (title: title, body: desc)
            }
            return nil
        }

        // Collect text from static text children
        var texts: [String] = []
        collectTexts(from: element, into: &texts, depth: 0)

        if texts.count >= 2 {
            return (title: texts[0], body: texts[1])
        } else if texts.count == 1 {
            return (title: texts[0], body: "")
        }

        // Recurse into children
        for child in children {
            if let result = findNotificationText(in: child) {
                return result
            }
        }

        return nil
    }

    private func collectTexts(from element: AXUIElement, into texts: inout [String], depth: Int) {
        guard depth < 10 else { return }

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = roleRef as? String

        if role == kAXStaticTextRole as String {
            var valueRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef) == .success,
               let text = valueRef as? String, !text.isEmpty {
                texts.append(text)
            }
        }

        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else { return }

        for child in children {
            collectTexts(from: child, into: &texts, depth: depth + 1)
        }
    }
}
