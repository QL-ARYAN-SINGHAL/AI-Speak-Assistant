//
//  AIVoiceAssistantApp.swift
//  AIVoiceAssistant
//
//  Created by KAKAROT on 3/13/26.
//

import SwiftUI
import FirebaseCore

@main
struct AIVoiceAssistantApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
