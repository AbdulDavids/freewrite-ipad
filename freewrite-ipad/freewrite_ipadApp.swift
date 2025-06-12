//
//  freewrite_ipadApp.swift
//  freewrite-ipad
//
//  Created by Abdul Baari Davids on 2025/06/12.
//

import SwiftUI

@main
struct freewrite_ipadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(nil) // Allow system color scheme
        }
        .windowResizability(.contentSize)
    }
}

// MARK: - iPad Orientation Support
extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
