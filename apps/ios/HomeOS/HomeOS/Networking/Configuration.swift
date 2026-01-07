import Foundation

enum Configuration {
    // Environment detection
    enum Environment {
        case development
        case staging
        case production

        static var current: Environment {
            #if DEBUG
            return .development
            #else
            // Check for staging builds via bundle identifier suffix
            if Bundle.main.bundleIdentifier?.contains(".staging") == true {
                return .staging
            }
            return .production
            #endif
        }
    }

    static var controlPlaneURL: String {
        switch Environment.current {
        case .development:
            return "http://localhost:3001"
        case .staging:
            return "https://homeos-control-plane.fly.dev"
        case .production:
            return "https://homeos-control-plane.fly.dev"  // Update to custom domain when available
        }
    }

    static var runtimeURL: String {
        switch Environment.current {
        case .development:
            return "http://localhost:3002"
        case .staging:
            return "https://homeos-runtime.fly.dev"
        case .production:
            return "https://homeos-runtime.fly.dev"  // Update to custom domain when available
        }
    }

    static var runtimeWSURL: String {
        switch Environment.current {
        case .development:
            return "ws://localhost:3002"
        case .staging:
            return "wss://homeos-runtime.fly.dev"
        case .production:
            return "wss://homeos-runtime.fly.dev"  // Update to custom domain when available
        }
    }

    // API Version
    static var apiVersion: String {
        return "v1"
    }
}
