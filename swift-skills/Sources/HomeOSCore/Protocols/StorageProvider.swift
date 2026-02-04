import Foundation

// MARK: - Storage Protocol

/// Abstraction over file-based JSON storage.
/// On iOS: reads/writes to app's Documents directory.
/// In tests: uses in-memory store.
public protocol StorageProvider: Sendable {
    /// Read a JSON file and decode it.
    func read<T: Decodable>(path: String, type: T.Type) async throws -> T
    
    /// Write a Codable value as JSON.
    func write<T: Encodable>(path: String, value: T) async throws
    
    /// Append an item to a JSON array file.
    func append<T: Encodable>(path: String, item: T) async throws
    
    /// Check if a file exists.
    func exists(path: String) async -> Bool
    
    /// Delete a file.
    func delete(path: String) async throws
    
    /// List files in a directory.
    func list(directory: String) async throws -> [String]
}

// MARK: - File Storage (Production)

public final class FileStorage: StorageProvider, @unchecked Sendable {
    private let baseURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    public init(baseDirectory: URL? = nil) {
        if let base = baseDirectory {
            self.baseURL = base
        } else {
            self.baseURL = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("homeos")
        }
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
        
        // Ensure base directory exists
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }
    
    public func read<T: Decodable>(path: String, type: T.Type) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }
    
    public func write<T: Encodable>(path: String, value: T) async throws {
        let url = baseURL.appendingPathComponent(path)
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try encoder.encode(value)
        try data.write(to: url)
    }
    
    public func append<T: Encodable>(path: String, item: T) async throws {
        let url = baseURL.appendingPathComponent(path)
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        
        var array: [Data] = []
        if let existingData = try? Data(contentsOf: url),
           let existing = try? JSONSerialization.jsonObject(with: existingData) as? [Any] {
            for element in existing {
                array.append(try JSONSerialization.data(withJSONObject: element))
            }
        }
        
        let itemData = try encoder.encode(item)
        let itemObject = try JSONSerialization.jsonObject(with: itemData)
        array.append(try JSONSerialization.data(withJSONObject: itemObject))
        
        let allObjects = try array.map { try JSONSerialization.jsonObject(with: $0) }
        let finalData = try JSONSerialization.data(withJSONObject: allObjects, options: .prettyPrinted)
        try finalData.write(to: url)
    }
    
    public func exists(path: String) async -> Bool {
        let url = baseURL.appendingPathComponent(path)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public func delete(path: String) async throws {
        let url = baseURL.appendingPathComponent(path)
        try FileManager.default.removeItem(at: url)
    }
    
    public func list(directory: String) async throws -> [String] {
        let url = baseURL.appendingPathComponent(directory)
        return try FileManager.default.contentsOfDirectory(atPath: url.path)
    }
}

// MARK: - In-Memory Storage (Testing)

public actor InMemoryStorage: StorageProvider {
    private var store: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {}
    
    /// Pre-load data for testing
    public func seed<T: Encodable>(path: String, value: T) throws {
        store[path] = try encoder.encode(value)
    }
    
    public func read<T: Decodable>(path: String, type: T.Type) async throws -> T {
        guard let data = store[path] else {
            throw StorageError.notFound(path)
        }
        return try decoder.decode(T.self, from: data)
    }
    
    public func write<T: Encodable>(path: String, value: T) async throws {
        store[path] = try encoder.encode(value)
    }
    
    public func append<T: Encodable>(path: String, item: T) async throws {
        let itemData = try encoder.encode([item])
        if let existingData = store[path] {
            var array = try JSONSerialization.jsonObject(with: existingData) as? [Any] ?? []
            let itemObj = try JSONSerialization.jsonObject(with: try encoder.encode(item))
            array.append(itemObj)
            store[path] = try JSONSerialization.data(withJSONObject: array)
        } else {
            store[path] = itemData
        }
    }
    
    public func exists(path: String) async -> Bool {
        store[path] != nil
    }
    
    public func delete(path: String) async throws {
        store.removeValue(forKey: path)
    }
    
    public func list(directory: String) async throws -> [String] {
        let prefix = directory.hasSuffix("/") ? directory : directory + "/"
        return store.keys.filter { $0.hasPrefix(prefix) }.map {
            String($0.dropFirst(prefix.count)).components(separatedBy: "/").first ?? ""
        }
    }
}

public enum StorageError: Error, LocalizedError {
    case notFound(String)
    case invalidData(String)
    
    public var errorDescription: String? {
        switch self {
        case .notFound(let path): return "File not found: \(path)"
        case .invalidData(let path): return "Invalid data at: \(path)"
        }
    }
}
