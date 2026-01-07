import Foundation

enum Configuration {
    static var controlPlaneURL: String {
        #if DEBUG
        return "http://localhost:3001"
        #else
        return "https://api.homeos.app"
        #endif
    }

    static var runtimeURL: String {
        #if DEBUG
        return "http://localhost:3002"
        #else
        return "https://runtime.homeos.app"
        #endif
    }

    static var runtimeWSURL: String {
        #if DEBUG
        return "ws://localhost:3002"
        #else
        return "wss://runtime.homeos.app"
        #endif
    }
}
