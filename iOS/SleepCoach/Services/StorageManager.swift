//
//  StorageManager.swift
//  SleepCoach
//
//  Local storage management for offline-first support
//

import Foundation

class StorageManager {
    static let shared = StorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private init() {}
    
    // MARK: - Sleep Logs Storage
    
    private var sleepLogsFile: URL {
        documentsDirectory.appendingPathComponent("sleep_logs.json")
    }
    
    func saveSleepLogs(_ logs: [SleepLog]) {
        do {
            let data = try JSONEncoder().encode(logs)
            try data.write(to: sleepLogsFile)
        } catch {
            print("Failed to save sleep logs: \(error)")
        }
    }
    
    func loadSleepLogs() -> [SleepLog] {
        guard fileManager.fileExists(atPath: sleepLogsFile.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: sleepLogsFile)
            return try JSONDecoder().decode([SleepLog].self, from: data)
        } catch {
            print("Failed to load sleep logs: \(error)")
            return []
        }
    }
    
    func appendSleepLog(_ log: SleepLog) {
        var logs = loadSleepLogs()
        logs.insert(log, at: 0)
        saveSleepLogs(logs)
    }
    
    func deleteSleepLog(id: String) {
        var logs = loadSleepLogs()
        logs.removeAll { $0.id == id }
        saveSleepLogs(logs)
    }
    
    // MARK: - Pending Sync Storage
    
    private var pendingSyncFile: URL {
        documentsDirectory.appendingPathComponent("pending_sync.json")
    }
    
    struct PendingSyncItem: Codable {
        let type: String  // "create" or "delete"
        let data: Data
        let timestamp: Date
    }
    
    func addPendingSync(type: String, data: Data) {
        var items = loadPendingSyncItems()
        items.append(PendingSyncItem(type: type, data: data, timestamp: Date()))
        savePendingSyncItems(items)
    }
    
    func loadPendingSyncItems() -> [PendingSyncItem] {
        guard fileManager.fileExists(atPath: pendingSyncFile.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: pendingSyncFile)
            return try JSONDecoder().decode([PendingSyncItem].self, from: data)
        } catch {
            print("Failed to load pending sync items: \(error)")
            return []
        }
    }
    
    func savePendingSyncItems(_ items: [PendingSyncItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: pendingSyncFile)
        } catch {
            print("Failed to save pending sync items: \(error)")
        }
    }
    
    func clearPendingSync() {
        try? fileManager.removeItem(at: pendingSyncFile)
    }
    
    func removePendingSyncItem(at index: Int) {
        var items = loadPendingSyncItems()
        guard index < items.count else { return }
        items.remove(at: index)
        savePendingSyncItems(items)
    }
    
    // MARK: - User Preferences
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(preferences) {
            userDefaults.set(data, forKey: "userPreferences")
        }
    }
    
    func loadUserPreferences() -> UserPreferences {
        guard let data = userDefaults.data(forKey: "userPreferences"),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences()
        }
        return preferences
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() {
        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
        
        // Clear files
        try? fileManager.removeItem(at: sleepLogsFile)
        try? fileManager.removeItem(at: pendingSyncFile)
    }
    
    // MARK: - Storage Info
    
    var storageUsed: Int64 {
        var total: Int64 = 0
        
        let files = [sleepLogsFile, pendingSyncFile]
        for file in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let size = attributes[.size] as? Int64 {
                total += size
            }
        }
        
        return total
    }
    
    var storageUsedFormatted: String {
        let bytes = storageUsed
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
