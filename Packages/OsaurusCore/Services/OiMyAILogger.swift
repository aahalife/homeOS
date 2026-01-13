//
//  OiMyAILogger.swift
//  OsaurusCore
//
//  Centralized logging infrastructure for Oi My AI.
//  Provides structured logging with categories, levels, and persistence.
//

import Foundation
import os.log

// MARK: - Log Level

/// Severity levels for log messages
public enum OiMyAILogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    public static func < (lhs: OiMyAILogLevel, rhs: OiMyAILogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

// MARK: - Log Category

/// Categories for organizing log messages
public enum OiMyAILogCategory: String, Sendable, CaseIterable {
    case app = "App"
    case chat = "Chat"
    case skills = "Skills"
    case tools = "Tools"
    case family = "Family"
    case telegram = "Telegram"
    case rube = "Rube"
    case mcp = "MCP"
    case model = "Model"
    case voice = "Voice"
    case network = "Network"
    case security = "Security"
    case performance = "Performance"

    var osLog: OSLog {
        OSLog(subsystem: "ai.oimyai", category: rawValue)
    }
}

// MARK: - Log Entry

/// A single log entry
public struct OiMyAILogEntry: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: OiMyAILogLevel
    public let category: OiMyAILogCategory
    public let message: String
    public let file: String
    public let function: String
    public let line: Int
    public let metadata: [String: String]?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: OiMyAILogLevel,
        category: OiMyAILogCategory,
        message: String,
        file: String,
        function: String,
        line: Int,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.metadata = metadata
    }

    /// Formatted log string
    public var formatted: String {
        let fileName = (file as NSString).lastPathComponent
        let meta = metadata?.map { "\($0.key)=\($0.value)" }.joined(separator: ", ") ?? ""
        let metaStr = meta.isEmpty ? "" : " [\(meta)]"

        return "\(level.emoji) [\(category.rawValue)] \(message)\(metaStr) (\(fileName):\(line))"
    }
}

// MARK: - Logger

/// Central logging service for Oi My AI
public final class OiMyAILogger: @unchecked Sendable {
    public static let shared = OiMyAILogger()

    /// Minimum log level to record
    public var minimumLevel: OiMyAILogLevel = .info

    /// Whether to print to console
    public var printToConsole: Bool = true

    /// Whether to use os_log
    public var useOSLog: Bool = true

    /// Maximum entries to keep in memory
    public var maxEntriesInMemory: Int = 1000

    /// In-memory log buffer (thread-safe)
    private var entries: [OiMyAILogEntry] = []
    private let lock = NSLock()

    /// Observers for real-time log updates
    private var observers: [(OiMyAILogEntry) -> Void] = []

    private init() {}

    // MARK: - Logging Methods

    public func debug(
        _ message: String,
        category: OiMyAILogCategory = .app,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        category: OiMyAILogCategory = .app,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        category: OiMyAILogCategory = .app,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        category: OiMyAILogCategory = .app,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    public func critical(
        _ message: String,
        category: OiMyAILogCategory = .app,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .critical, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    // MARK: - Core Logging

    public func log(
        level: OiMyAILogLevel,
        message: String,
        category: OiMyAILogCategory,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level >= minimumLevel else { return }

        let entry = OiMyAILogEntry(
            level: level,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line,
            metadata: metadata
        )

        // Store in memory
        lock.lock()
        entries.append(entry)
        if entries.count > maxEntriesInMemory {
            entries.removeFirst(entries.count - maxEntriesInMemory)
        }
        let currentObservers = observers
        lock.unlock()

        // Print to console
        if printToConsole {
            print("[Oi My AI] \(entry.formatted)")
        }

        // Log to os_log
        if useOSLog {
            os_log("%{public}@", log: category.osLog, type: level.osLogType, entry.formatted)
        }

        // Notify observers
        for observer in currentObservers {
            observer(entry)
        }
    }

    // MARK: - Entry Access

    /// Get all entries (thread-safe copy)
    public func allEntries() -> [OiMyAILogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    /// Get entries filtered by category
    public func entries(for category: OiMyAILogCategory) -> [OiMyAILogEntry] {
        allEntries().filter { $0.category == category }
    }

    /// Get entries filtered by level
    public func entries(minLevel: OiMyAILogLevel) -> [OiMyAILogEntry] {
        allEntries().filter { $0.level >= minLevel }
    }

    /// Clear all entries
    public func clear() {
        lock.lock()
        entries.removeAll()
        lock.unlock()
    }

    // MARK: - Observers

    /// Add an observer for real-time log updates
    public func addObserver(_ observer: @escaping (OiMyAILogEntry) -> Void) {
        lock.lock()
        observers.append(observer)
        lock.unlock()
    }

    /// Remove all observers
    public func removeAllObservers() {
        lock.lock()
        observers.removeAll()
        lock.unlock()
    }

    // MARK: - Export

    /// Export logs as formatted text
    public func exportAsText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        return allEntries().map { entry in
            "\(formatter.string(from: entry.timestamp)) \(entry.formatted)"
        }.joined(separator: "\n")
    }

    /// Export logs as JSON
    public func exportAsJSON() -> Data? {
        let formatter = ISO8601DateFormatter()

        let jsonEntries = allEntries().map { entry -> [String: Any] in
            var dict: [String: Any] = [
                "timestamp": formatter.string(from: entry.timestamp),
                "level": entry.level.rawValue,
                "category": entry.category.rawValue,
                "message": entry.message,
                "file": (entry.file as NSString).lastPathComponent,
                "function": entry.function,
                "line": entry.line
            ]
            if let meta = entry.metadata {
                dict["metadata"] = meta
            }
            return dict
        }

        return try? JSONSerialization.data(withJSONObject: jsonEntries, options: .prettyPrinted)
    }
}

// MARK: - Convenience Functions

/// Global logging functions for easy access
public func logDebug(_ message: String, category: OiMyAILogCategory = .app, metadata: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    OiMyAILogger.shared.debug(message, category: category, metadata: metadata, file: file, function: function, line: line)
}

public func logInfo(_ message: String, category: OiMyAILogCategory = .app, metadata: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    OiMyAILogger.shared.info(message, category: category, metadata: metadata, file: file, function: function, line: line)
}

public func logWarning(_ message: String, category: OiMyAILogCategory = .app, metadata: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    OiMyAILogger.shared.warning(message, category: category, metadata: metadata, file: file, function: function, line: line)
}

public func logError(_ message: String, category: OiMyAILogCategory = .app, metadata: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    OiMyAILogger.shared.error(message, category: category, metadata: metadata, file: file, function: function, line: line)
}

public func logCritical(_ message: String, category: OiMyAILogCategory = .app, metadata: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    OiMyAILogger.shared.critical(message, category: category, metadata: metadata, file: file, function: function, line: line)
}
