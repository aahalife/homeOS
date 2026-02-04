import Foundation

// MARK: - LLM Bridge Protocol

/// Abstraction over on-device LLM (Gemma 3n via MediaPipe).
/// Keeps skill logic decoupled from specific inference implementation.
public protocol LLMBridge: Sendable {
    /// Generate a free-form text response.
    func generate(prompt: String) async throws -> String
    
    /// Generate a structured JSON response conforming to a schema.
    /// The LLM is instructed to output ONLY valid JSON matching the schema.
    func generateJSON(prompt: String, schema: JSONSchema) async throws -> String
    
    /// Classify input into one of the given categories.
    /// Returns the category name.
    func classify(input: String, categories: [ClassificationCategory]) async throws -> String
    
    /// Summarize text to a target length.
    func summarize(text: String, maxWords: Int) async throws -> String
}

// MARK: - Supporting Types

public struct JSONSchema: Sendable {
    public let schemaString: String
    
    public init(_ schema: String) {
        self.schemaString = schema
    }
    
    /// Convenience for common schemas
    public static func object(properties: [String: String]) -> JSONSchema {
        var props: [String] = []
        var required: [String] = []
        for (key, type) in properties.sorted(by: { $0.key < $1.key }) {
            props.append("\"\(key)\": { \"type\": \"\(type)\" }")
            required.append("\"\(key)\"")
        }
        return JSONSchema("""
        {
            "type": "object",
            "properties": { \(props.joined(separator: ", ")) },
            "required": [\(required.joined(separator: ", "))],
            "additionalProperties": false
        }
        """)
    }
}

public struct ClassificationCategory: Sendable {
    public let name: String
    public let description: String
    public let examples: [String]
    
    public init(name: String, description: String, examples: [String] = []) {
        self.name = name
        self.description = description
        self.examples = examples
    }
}

// MARK: - MediaPipe Gemma 3n Bridge

/// Production implementation using MediaPipe's LLM Inference API.
/// Wire this up to your MediaPipe setup in the iOS app.
public final class MediaPipeGemmaBridge: LLMBridge, @unchecked Sendable {
    
    // Placeholder — the app will inject the actual MediaPipe inference instance
    public typealias InferenceFunction = @Sendable (String) async throws -> String
    
    private let infer: InferenceFunction
    
    public init(inferenceFunction: @escaping InferenceFunction) {
        self.infer = inferenceFunction
    }
    
    public func generate(prompt: String) async throws -> String {
        try await infer(prompt)
    }
    
    public func generateJSON(prompt: String, schema: JSONSchema) async throws -> String {
        let fullPrompt = """
        \(prompt)
        
        Respond with ONLY valid JSON matching this schema:
        \(schema.schemaString)
        
        Output ONLY the JSON object, no explanation, no markdown.
        """
        let response = try await infer(fullPrompt)
        // Extract JSON from response (handle potential preamble)
        return extractJSON(from: response)
    }
    
    public func classify(input: String, categories: [ClassificationCategory]) async throws -> String {
        let categoryList = categories.map { cat in
            var desc = "- \(cat.name): \(cat.description)"
            if !cat.examples.isEmpty {
                desc += " (examples: \(cat.examples.joined(separator: ", ")))"
            }
            return desc
        }.joined(separator: "\n")
        
        let prompt = """
        Classify the following input into exactly ONE category.
        
        Input: "\(input)"
        
        Categories:
        \(categoryList)
        
        Respond with ONLY the category name, nothing else.
        """
        
        let response = try await infer(prompt)
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate response is a known category
        if let match = categories.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            return match.name
        }
        // Fuzzy match — find best match
        if let match = categories.first(where: { trimmed.lowercased().contains($0.name.lowercased()) }) {
            return match.name
        }
        // Default to first category if LLM gave garbage
        return categories.first?.name ?? trimmed
    }
    
    public func summarize(text: String, maxWords: Int) async throws -> String {
        let prompt = """
        Summarize the following text in \(maxWords) words or fewer.
        Be concise and capture the key points.
        
        Text: \(text)
        
        Summary:
        """
        return try await infer(prompt)
    }
    
    /// Extract JSON from a response that might have extra text
    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find JSON object
        if let start = trimmed.firstIndex(of: "{"),
           let end = trimmed.lastIndex(of: "}") {
            return String(trimmed[start...end])
        }
        
        // Try to find JSON array
        if let start = trimmed.firstIndex(of: "["),
           let end = trimmed.lastIndex(of: "]") {
            return String(trimmed[start...end])
        }
        
        return trimmed
    }
}

// MARK: - Mock LLM (Testing)

public final class MockLLMBridge: LLMBridge, @unchecked Sendable {
    public var generateResponses: [String: String] = [:]
    public var classifyResponses: [String: String] = [:]
    public var defaultResponse: String = "{}"
    
    public init() {}
    
    public func generate(prompt: String) async throws -> String {
        for (key, value) in generateResponses {
            if prompt.contains(key) { return value }
        }
        return defaultResponse
    }
    
    public func generateJSON(prompt: String, schema: JSONSchema) async throws -> String {
        for (key, value) in generateResponses {
            if prompt.contains(key) { return value }
        }
        return defaultResponse
    }
    
    public func classify(input: String, categories: [ClassificationCategory]) async throws -> String {
        for (key, value) in classifyResponses {
            if input.contains(key) { return value }
        }
        return categories.first?.name ?? "unknown"
    }
    
    public func summarize(text: String, maxWords: Int) async throws -> String {
        return String(text.prefix(maxWords * 6)) // ~6 chars per word
    }
}
