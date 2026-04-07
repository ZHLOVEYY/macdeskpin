import Foundation
import AppKit

/// Lightweight self-updater:
/// 1. On launch, GET a remote version.json
/// 2. Compare with local version
/// 3. If newer, show a notification with download link
/// 4. User downloads DMG manually — their data in ~/Library/Application Support/DeskPin/ is untouched
///
/// version.json format (host on GitHub Releases, your server, etc.):
/// {
///   "version": "1.1.0",
///   "download_url": "https://github.com/yourname/DeskPin/releases/download/v1.1.0/DeskPin-1.1.0.dmg",
///   "release_notes": "Bug fixes and new features"
/// }

struct RemoteVersion: Decodable {
    let version: String
    let downloadUrl: String
    let releaseNotes: String?

    enum CodingKeys: String, CodingKey {
        case version
        case downloadUrl = "download_url"
        case releaseNotes = "release_notes"
    }
}

class UpdateChecker {
    static let currentVersion = "1.0.0"

    /// Set this to your hosted version.json URL
    /// Example: "https://raw.githubusercontent.com/yourname/DeskPin/main/version.json"
    static var updateURL: String? {
        // Read from config file, or use a hardcoded default
        let configURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("DeskPin/update_url.txt")
        if let url = try? String(contentsOf: configURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           !url.isEmpty {
            return url
        }
        return nil // No update URL configured — skip update check
    }

    static func checkForUpdates(silent: Bool = true) {
        guard let urlString = updateURL, let url = URL(string: urlString) else {
            if !silent {
                showAlert(title: "Update check not configured",
                          message: "Place your version.json URL in:\n~/Library/Application Support/DeskPin/update_url.txt")
            }
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                if !silent {
                    DispatchQueue.main.async {
                        showAlert(title: "Update check failed", message: error?.localizedDescription ?? "Network error")
                    }
                }
                return
            }

            guard let remote = try? JSONDecoder().decode(RemoteVersion.self, from: data) else {
                if !silent {
                    DispatchQueue.main.async {
                        showAlert(title: "Update check failed", message: "Invalid version.json format")
                    }
                }
                return
            }

            DispatchQueue.main.async {
                if isNewer(remote: remote.version, local: currentVersion) {
                    showUpdateAvailable(remote)
                } else if !silent {
                    showAlert(title: "Up to date", message: "DeskPin \(currentVersion) is the latest version.")
                }
            }
        }
        task.resume()
    }

    private static func isNewer(remote: String, local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }

    private static func showUpdateAvailable(_ remote: RemoteVersion) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "DeskPin \(remote.version) Available"
        alert.informativeText = """
            Current version: \(currentVersion)
            New version: \(remote.version)
            \(remote.releaseNotes ?? "")

            Your data will not be affected by the update.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: remote.downloadUrl) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private static func showAlert(title: String, message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
}
