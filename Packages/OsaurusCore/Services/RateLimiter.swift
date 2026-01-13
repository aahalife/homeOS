//
//  RateLimiter.swift
//  OsaurusCore
//
//  General-purpose rate limiting utility for Oi My AI.
//  Provides sliding window and fixed window rate limiting.
//

import Foundation

// MARK: - Rate Limiter

/// A general-purpose rate limiter with support for multiple strategies
public actor RateLimiter {

    // MARK: - Types

    /// Rate limiting strategy
    public enum Strategy: Sendable {
        /// Fixed window: resets at fixed intervals
        case fixedWindow
        /// Sliding window: continuous rolling window
        case slidingWindow
        /// Token bucket: allows bursts up to bucket size
        case tokenBucket(bucketSize: Int)
    }

    /// Result of a rate limit check
    public struct Result: Sendable {
        public let allowed: Bool
        public let remaining: Int
        public let resetTime: Date
        public let retryAfter: TimeInterval?

        public init(allowed: Bool, remaining: Int, resetTime: Date, retryAfter: TimeInterval? = nil) {
            self.allowed = allowed
            self.remaining = remaining
            self.resetTime = resetTime
            self.retryAfter = retryAfter
        }
    }

    // MARK: - Properties

    private let limit: Int
    private let windowDuration: TimeInterval
    private let strategy: Strategy

    /// Tracks requests per key
    private var windows: [String: WindowData] = [:]

    /// Cleanup interval
    private var lastCleanup: Date = Date()
    private let cleanupInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    /// Create a rate limiter
    /// - Parameters:
    ///   - limit: Maximum number of requests per window
    ///   - windowDuration: Duration of the rate limit window in seconds
    ///   - strategy: Rate limiting strategy to use
    public init(limit: Int, windowDuration: TimeInterval, strategy: Strategy = .slidingWindow) {
        self.limit = limit
        self.windowDuration = windowDuration
        self.strategy = strategy
    }

    // MARK: - Public API

    /// Check if a request should be allowed for the given key
    /// - Parameter key: Identifier for the rate limit bucket (e.g., user ID, IP)
    /// - Returns: Result indicating if the request is allowed
    public func check(key: String) -> Result {
        cleanupIfNeeded()

        let now = Date()
        var window = windows[key] ?? WindowData(windowStart: now, timestamps: [])

        switch strategy {
        case .fixedWindow:
            return checkFixedWindow(key: key, window: &window, now: now)
        case .slidingWindow:
            return checkSlidingWindow(key: key, window: &window, now: now)
        case .tokenBucket(let bucketSize):
            return checkTokenBucket(key: key, window: &window, now: now, bucketSize: bucketSize)
        }
    }

    /// Record a request for the given key (use after check returns allowed)
    /// - Parameter key: Identifier for the rate limit bucket
    public func record(key: String) {
        let now = Date()
        var window = windows[key] ?? WindowData(windowStart: now, timestamps: [])
        window.timestamps.append(now)
        windows[key] = window
    }

    /// Check and record in one operation (atomic)
    /// - Parameter key: Identifier for the rate limit bucket
    /// - Returns: Result indicating if the request is allowed
    public func checkAndRecord(key: String) -> Result {
        let result = check(key: key)
        if result.allowed {
            record(key: key)
        }
        return result
    }

    /// Reset the rate limit for a specific key
    /// - Parameter key: Identifier for the rate limit bucket
    public func reset(key: String) {
        windows.removeValue(forKey: key)
    }

    /// Reset all rate limits
    public func resetAll() {
        windows.removeAll()
    }

    /// Get current status for a key without recording
    /// - Parameter key: Identifier for the rate limit bucket
    /// - Returns: Current remaining requests and reset time
    public func status(key: String) -> (remaining: Int, resetTime: Date) {
        let result = check(key: key)
        return (result.remaining, result.resetTime)
    }

    // MARK: - Strategy Implementations

    private func checkFixedWindow(key: String, window: inout WindowData, now: Date) -> Result {
        let windowEnd = window.windowStart.addingTimeInterval(windowDuration)

        // Check if we need to start a new window
        if now >= windowEnd {
            window = WindowData(windowStart: now, timestamps: [])
            windows[key] = window
        }

        let count = window.timestamps.count
        let remaining = max(0, limit - count)
        let resetTime = window.windowStart.addingTimeInterval(windowDuration)

        if count >= limit {
            return Result(
                allowed: false,
                remaining: 0,
                resetTime: resetTime,
                retryAfter: resetTime.timeIntervalSince(now)
            )
        }

        return Result(allowed: true, remaining: remaining - 1, resetTime: resetTime)
    }

    private func checkSlidingWindow(key: String, window: inout WindowData, now: Date) -> Result {
        // Remove timestamps outside the window
        let cutoff = now.addingTimeInterval(-windowDuration)
        window.timestamps = window.timestamps.filter { $0 > cutoff }
        windows[key] = window

        let count = window.timestamps.count
        let remaining = max(0, limit - count)
        let resetTime = now.addingTimeInterval(windowDuration)

        if count >= limit {
            // Find when the oldest request will expire
            let oldestExpiry = window.timestamps.first?.addingTimeInterval(windowDuration) ?? resetTime
            return Result(
                allowed: false,
                remaining: 0,
                resetTime: oldestExpiry,
                retryAfter: oldestExpiry.timeIntervalSince(now)
            )
        }

        return Result(allowed: true, remaining: remaining - 1, resetTime: resetTime)
    }

    private func checkTokenBucket(key: String, window: inout WindowData, now: Date, bucketSize: Int) -> Result {
        // Calculate tokens refilled since last request
        let timeSinceStart = now.timeIntervalSince(window.windowStart)
        let tokensRefilled = Int(timeSinceStart / windowDuration * Double(limit))

        // Current tokens = min(bucket size, refilled tokens - consumed)
        let consumed = window.timestamps.count
        let currentTokens = min(bucketSize, max(0, tokensRefilled - consumed))

        let resetTime = now.addingTimeInterval(windowDuration / Double(limit))

        if currentTokens <= 0 {
            return Result(
                allowed: false,
                remaining: 0,
                resetTime: resetTime,
                retryAfter: windowDuration / Double(limit)
            )
        }

        return Result(allowed: true, remaining: currentTokens - 1, resetTime: resetTime)
    }

    // MARK: - Cleanup

    private func cleanupIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastCleanup) > cleanupInterval else { return }

        lastCleanup = now
        let cutoff = now.addingTimeInterval(-windowDuration * 2)

        // Remove stale windows
        windows = windows.filter { _, window in
            guard let lastTimestamp = window.timestamps.last else {
                return window.windowStart > cutoff
            }
            return lastTimestamp > cutoff
        }
    }
}

// MARK: - Window Data

private struct WindowData {
    var windowStart: Date
    var timestamps: [Date]
}

// MARK: - Preset Rate Limiters

extension RateLimiter {
    /// Rate limiter for API calls (60 per minute)
    public static let api = RateLimiter(limit: 60, windowDuration: 60, strategy: .slidingWindow)

    /// Rate limiter for skill executions (30 per minute)
    public static let skills = RateLimiter(limit: 30, windowDuration: 60, strategy: .slidingWindow)

    /// Rate limiter for tool calls (100 per minute)
    public static let tools = RateLimiter(limit: 100, windowDuration: 60, strategy: .slidingWindow)

    /// Rate limiter for family operations (10 per minute)
    public static let family = RateLimiter(limit: 10, windowDuration: 60, strategy: .fixedWindow)

    /// Rate limiter for telegram messages (20 per minute per user)
    public static let telegram = RateLimiter(limit: 20, windowDuration: 60, strategy: .slidingWindow)
}

// MARK: - Convenience Extensions

extension RateLimiter {
    /// Check if a request is allowed for the given user
    public func isAllowed(for userId: String) async -> Bool {
        let result = await checkAndRecord(key: userId)
        return result.allowed
    }

    /// Get remaining requests for a user
    public func remaining(for userId: String) async -> Int {
        let (remaining, _) = await status(key: userId)
        return remaining
    }
}
