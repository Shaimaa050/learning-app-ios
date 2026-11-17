import Foundation

enum LearningDuration: String, Codable {
    case week
    case month
    case year
    
    func endDate(from startDate: Date) -> Date? {
        let calendar = Calendar.current

        switch self {
        case .week:
            return calendar.date(
                byAdding: .weekOfYear,
                value: 1,
                to: startDate
            )
        case .month:
            return calendar.date(
                byAdding: .month,
                value: 1,
                to: startDate
            )
        case .year:
            return calendar.date(
                byAdding: .year,
                value: 1,
                to: startDate
            )
        }
        
        
    }
    
    
    
    var freezeLimit: Int {
        switch self {
        case .week:
            return 2
        case .month:
            return 8
        case .year:
            return 96
        }
    }
}

struct LearningPreferences {
    var topic: String = ""
    var duration: LearningDuration = .week
}




//  LearningPreferences.swift
//  LearningApp
//
//  Created by Shaima Basaleh on 29/05/1448 AH.
//

