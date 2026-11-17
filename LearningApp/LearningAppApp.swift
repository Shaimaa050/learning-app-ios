//
//  LearningAppApp.swift
//  LearningApp
//
//  Created by Shaima Basaleh on 29/05/1448 AH.
//

import SwiftUI
import SwiftData

@main
struct LearningAppApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView()
        }
        .modelContainer(for: [
            LearningGoal.self,
            LearningDay.self
        ])
    }
}
