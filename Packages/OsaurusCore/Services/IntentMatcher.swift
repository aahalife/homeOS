//
//  IntentMatcher.swift
//  OsaurusCore
//
//  Matches user input to skill triggers with confidence scoring.
//  Provides fast-path skill detection before LLM invocation.
//

import Foundation
import SkillsKit

// MARK: - Intent Match Result

/// Result of intent matching against skills
public struct IntentMatchResult: Sendable {
    /// The matched skill definition
    public let skill: SkillDefinition

    /// Confidence score (0.0 to 1.0)
    public let confidence: Double

    /// The trigger that matched
    public let matchedTrigger: String

    /// Match type (exact, fuzzy, voice, example)
    public let matchType: IntentMatchType

    /// Extracted parameters from the input
    public let extractedParams: [String: String]

    public init(
        skill: SkillDefinition,
        confidence: Double,
        matchedTrigger: String,
        matchType: IntentMatchType,
        extractedParams: [String: String] = [:]
    ) {
        self.skill = skill
        self.confidence = confidence
        self.matchedTrigger = matchedTrigger
        self.matchType = matchType
        self.extractedParams = extractedParams
    }
}

/// Type of match that occurred
public enum IntentMatchType: String, Sendable {
    case exactTrigger = "exact"
    case fuzzyTrigger = "fuzzy"
    case voiceTrigger = "voice"
    case examplePrompt = "example"
    case keywordMatch = "keyword"
}

// MARK: - Intent Matcher

/// Matches user input to registered skills
@MainActor
public final class IntentMatcher: @unchecked Sendable {
    public static let shared = IntentMatcher()

    /// Minimum confidence threshold for a match
    public var minimumConfidence: Double = 0.6

    /// Whether to use fuzzy matching
    public var enableFuzzyMatching: Bool = true

    private init() {}

    // MARK: - Public API

    /// Match user input against all loaded skills
    /// Returns matches sorted by confidence (highest first)
    public func match(input: String) async -> [IntentMatchResult] {
        let normalizedInput = normalizeInput(input)
        var matches: [IntentMatchResult] = []

        // Get all loaded skills from SkillLoader
        let skills = SkillLoader.shared.allSkills

        for skill in skills {
            if let result = matchSkill(skill, against: normalizedInput, original: input) {
                if result.confidence >= minimumConfidence {
                    matches.append(result)
                }
            }
        }

        // Sort by confidence (highest first)
        return matches.sorted { $0.confidence > $1.confidence }
    }

    /// Get the best match if confidence is above threshold
    public func bestMatch(input: String) async -> IntentMatchResult? {
        let matches = await match(input: input)
        return matches.first
    }

    /// Check if input matches a specific skill
    public func matches(input: String, skillId: String) async -> IntentMatchResult? {
        guard let skill = SkillLoader.shared.skill(withId: skillId) else {
            return nil
        }

        let normalizedInput = normalizeInput(input)
        return matchSkill(skill, against: normalizedInput, original: input)
    }

    // MARK: - Private Matching Logic

    private func matchSkill(_ skill: SkillDefinition, against normalizedInput: String, original: String) -> IntentMatchResult? {
        var bestMatch: IntentMatchResult?
        var highestConfidence: Double = 0

        // 1. Check voice triggers (highest priority for voice input)
        for trigger in skill.voiceTriggers {
            let confidence = matchTrigger(trigger, against: normalizedInput)
            if confidence > highestConfidence {
                highestConfidence = confidence
                bestMatch = IntentMatchResult(
                    skill: skill,
                    confidence: confidence,
                    matchedTrigger: trigger,
                    matchType: .voiceTrigger,
                    extractedParams: extractParams(from: original, trigger: trigger)
                )
            }
        }

        // 2. Check example prompts
        for example in skill.examplePrompts {
            let confidence = matchExample(example, against: normalizedInput)
            if confidence > highestConfidence {
                highestConfidence = confidence
                bestMatch = IntentMatchResult(
                    skill: skill,
                    confidence: confidence,
                    matchedTrigger: example,
                    matchType: .examplePrompt,
                    extractedParams: extractParams(from: original, trigger: example)
                )
            }
        }

        // 3. Check keyword matching based on skill name and description
        let keywordConfidence = matchKeywords(skill, against: normalizedInput)
        if keywordConfidence > highestConfidence {
            highestConfidence = keywordConfidence
            bestMatch = IntentMatchResult(
                skill: skill,
                confidence: keywordConfidence,
                matchedTrigger: skill.name,
                matchType: .keywordMatch,
                extractedParams: [:]
            )
        }

        return bestMatch
    }

    private func matchTrigger(_ trigger: String, against input: String) -> Double {
        let normalizedTrigger = normalizeInput(trigger)

        // Exact match
        if input == normalizedTrigger {
            return 1.0
        }

        // Contains the full trigger
        if input.contains(normalizedTrigger) {
            return 0.9
        }

        // Trigger contains input
        if normalizedTrigger.contains(input) && input.count > 3 {
            return 0.7
        }

        // Fuzzy matching
        if enableFuzzyMatching {
            let similarity = stringSimilarity(input, normalizedTrigger)
            if similarity > 0.7 {
                return similarity * 0.8 // Scale down fuzzy matches
            }
        }

        return 0
    }

    private func matchExample(_ example: String, against input: String) -> Double {
        let normalizedExample = normalizeInput(example)

        // High similarity to example prompt
        let similarity = stringSimilarity(input, normalizedExample)

        if similarity > 0.8 {
            return similarity * 0.95 // Example prompts are strong indicators
        }

        // Check if key parts of the example are in input
        let exampleWords = Set(normalizedExample.split(separator: " ").map(String.init))
        let inputWords = Set(input.split(separator: " ").map(String.init))

        let commonWords = exampleWords.intersection(inputWords)
        let significantWords = exampleWords.filter { $0.count > 3 } // Filter out small words

        if !significantWords.isEmpty {
            let overlap = Double(commonWords.intersection(significantWords).count) / Double(significantWords.count)
            if overlap > 0.5 {
                return overlap * 0.75
            }
        }

        return 0
    }

    private func matchKeywords(_ skill: SkillDefinition, against input: String) -> Double {
        var score: Double = 0

        // Check skill name
        let nameWords = normalizeInput(skill.name).split(separator: " ").map(String.init)
        let inputWords = Set(input.split(separator: " ").map(String.init))

        for word in nameWords where word.count > 2 {
            if inputWords.contains(word) {
                score += 0.3
            }
        }

        // Check category keywords
        let categoryKeywords = categoryToKeywords(skill.category)
        for keyword in categoryKeywords {
            if input.contains(keyword) {
                score += 0.2
            }
        }

        // Check description keywords
        let descWords = normalizeInput(skill.shortDescription).split(separator: " ").map(String.init)
        let significantDescWords = descWords.filter { $0.count > 4 }

        for word in significantDescWords {
            if inputWords.contains(word) {
                score += 0.15
            }
        }

        return min(score, 0.8) // Cap keyword matching at 0.8
    }

    // MARK: - Parameter Extraction

    private func extractParams(from input: String, trigger: String) -> [String: String] {
        var params: [String: String] = [:]

        // Extract time-related parameters
        if let time = extractTime(from: input) {
            params["time"] = time
        }

        // Extract date-related parameters
        if let date = extractDate(from: input) {
            params["date"] = date
        }

        // Extract location
        if let location = extractLocation(from: input) {
            params["location"] = location
        }

        // Extract quantity/number
        if let number = extractNumber(from: input) {
            params["quantity"] = number
        }

        return params
    }

    private func extractTime(from input: String) -> String? {
        let timePatterns = [
            #"(\d{1,2}:\d{2}\s*(?:am|pm)?)"#,
            #"(\d{1,2}\s*(?:am|pm))"#,
            #"(morning|afternoon|evening|night|noon|midnight)"#
        ]

        for pattern in timePatterns {
            if let range = input.range(of: pattern, options: .regularExpression, range: nil, locale: nil) {
                return String(input[range])
            }
        }
        return nil
    }

    private func extractDate(from input: String) -> String? {
        let datePatterns = [
            #"(today|tomorrow|yesterday)"#,
            #"(monday|tuesday|wednesday|thursday|friday|saturday|sunday)"#,
            #"(\d{1,2}/\d{1,2}(?:/\d{2,4})?)"#,
            #"(next week|this week|next month)"#
        ]

        let lowercased = input.lowercased()
        for pattern in datePatterns {
            if let range = lowercased.range(of: pattern, options: .regularExpression, range: nil, locale: nil) {
                return String(lowercased[range])
            }
        }
        return nil
    }

    private func extractLocation(from input: String) -> String? {
        // Look for "in <location>", "at <location>", "near <location>"
        let patterns = [
            #"(?:in|at|near|around)\s+([A-Z][a-zA-Z\s]+?)(?:\s+(?:at|on|for|tomorrow|today)|$)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: input, options: [], range: NSRange(input.startIndex..., in: input)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: input) {
                return String(input[range]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private func extractNumber(from input: String) -> String? {
        let pattern = #"\b(\d+)\b"#
        if let range = input.range(of: pattern, options: .regularExpression) {
            return String(input[range])
        }
        return nil
    }

    // MARK: - Helpers

    private func normalizeInput(_ input: String) -> String {
        input
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"[^\w\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        // Jaccard similarity on word sets
        let words1 = Set(s1.split(separator: " ").map(String.init))
        let words2 = Set(s2.split(separator: " ").map(String.init))

        guard !words1.isEmpty || !words2.isEmpty else { return 0 }

        let intersection = words1.intersection(words2)
        let union = words1.union(words2)

        return Double(intersection.count) / Double(union.count)
    }

    private func categoryToKeywords(_ category: String) -> [String] {
        switch category.lowercased() {
        case "meal planning", "food":
            return ["meal", "recipe", "cook", "dinner", "lunch", "breakfast", "food", "eat", "grocery"]
        case "calendar", "scheduling":
            return ["calendar", "schedule", "event", "appointment", "meeting", "remind"]
        case "healthcare", "health":
            return ["health", "doctor", "appointment", "medical", "symptom", "medicine"]
        case "weather":
            return ["weather", "forecast", "temperature", "rain", "sunny", "cold", "hot"]
        case "home services", "services":
            return ["hire", "help", "service", "repair", "clean", "handyman", "plumber"]
        default:
            return []
        }
    }
}

// MARK: - Intent Matcher Configuration

extension IntentMatcher {
    /// Configuration for intent matching behavior
    public struct Configuration {
        public var minimumConfidence: Double
        public var enableFuzzyMatching: Bool
        public var prioritizeVoiceTriggers: Bool

        public static let `default` = Configuration(
            minimumConfidence: 0.6,
            enableFuzzyMatching: true,
            prioritizeVoiceTriggers: true
        )
    }

    /// Apply configuration
    public func configure(_ config: Configuration) {
        minimumConfidence = config.minimumConfidence
        enableFuzzyMatching = config.enableFuzzyMatching
    }
}
