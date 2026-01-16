//
//  momentsApp.swift
//  moments
//
//  Created by BHARATH SUDHARSAN on 1/15/26.
//

import SwiftUI

@main
struct momentsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SessionManager.shared)
        }
    }
}
