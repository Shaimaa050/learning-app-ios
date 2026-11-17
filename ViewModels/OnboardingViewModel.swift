import Observation
import Foundation

@Observable
class OnboardingViewModel {
    var preferences = LearningPreferences()
    
    var canStartLearning: Bool {
        !preferences.topic
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
    
    func makeGoal() -> LearningGoal? {
        guard canStartLearning else {
            return nil
        }

        let startDate = Calendar.current.startOfDay(for: Date())
        
        guard let endDate = preferences.duration.endDate(from: startDate) else {
            return nil
        }

        return LearningGoal(
            topic: preferences.topic.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: preferences.duration,
            startDate: startDate,
            endDate: endDate
        )
    }
}


//  OnboardingViewModel.swift
//  LearningApp
//
//  Created by Shaima Basaleh on 29/05/1448 AH.
//

