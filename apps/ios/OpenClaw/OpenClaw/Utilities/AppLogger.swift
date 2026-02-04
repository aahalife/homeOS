import Foundation
import os.log

/// Centralized logging system for OpenClaw
final class AppLogger {
    static let shared = AppLogger()

    private let logger: Logger

    private init() {
        self.logger = Logger(subsystem: "com.aahalife.openclaw", category: "general")
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        logger.info("[\(filename):\(line)] \(message)")
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        logger.warning("[\(filename):\(line)] \(message)")
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        logger.error("[\(filename):\(line)] \(message)")
    }

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        logger.debug("[\(filename):\(line)] \(message)")
        #endif
    }

    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        logger.critical("[\(filename):\(line)] \(message)")
    }

    // MARK: - Skill-specific loggers

    static func skill(_ skill: SkillType) -> Logger {
        Logger(subsystem: "com.aahalife.openclaw", category: "skill.\(skill.rawValue)")
    }

    static func api(_ name: String) -> Logger {
        Logger(subsystem: "com.aahalife.openclaw", category: "api.\(name)")
    }

    static let network = Logger(subsystem: "com.aahalife.openclaw", category: "network")
    static let persistence = Logger(subsystem: "com.aahalife.openclaw", category: "persistence")
    static let ai = Logger(subsystem: "com.aahalife.openclaw", category: "ai")
}
