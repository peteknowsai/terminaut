import Foundation

/// Manages archived background tasks stored in ~/.terminaut/tasks.json
class TaskArchiveManager {
    static let shared = TaskArchiveManager()

    private let fileURL: URL

    private init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let terminautDir = homeDir.appendingPathComponent(".terminaut")
        fileURL = terminautDir.appendingPathComponent("tasks.json")

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: terminautDir, withIntermediateDirectories: true)
    }

    /// Archive a task by session ID
    func archiveTask(sessionId: String) {
        var archived = loadArchivedTasks()
        if !archived.contains(sessionId) {
            archived.append(sessionId)
            saveArchivedTasks(archived)
        }
    }

    /// Unarchive a task by session ID
    func unarchiveTask(sessionId: String) {
        var archived = loadArchivedTasks()
        archived.removeAll { $0 == sessionId }
        saveArchivedTasks(archived)
    }

    /// Check if a task is archived
    func isArchived(sessionId: String) -> Bool {
        return loadArchivedTasks().contains(sessionId)
    }

    /// Load archived task IDs from file
    private func loadArchivedTasks() -> [String] {
        guard let data = try? Data(contentsOf: fileURL),
              let json = try? JSONDecoder().decode(ArchivedTasks.self, from: data) else {
            return []
        }
        return json.archived
    }

    /// Save archived task IDs to file
    private func saveArchivedTasks(_ tasks: [String]) {
        let json = ArchivedTasks(archived: tasks)
        guard let data = try? JSONEncoder().encode(json) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private struct ArchivedTasks: Codable {
        var archived: [String]
    }
}
