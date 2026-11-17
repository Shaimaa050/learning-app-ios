import Foundation
import SwiftData

enum LearningDayStatus: String, Codable {
    case learned
    case frozen
}

@Model
final class LearningDay {
    var date: Date
    var status: LearningDayStatus
    var goal: LearningGoal?
    var recordedAt: Date

    init(
        date: Date,
        status: LearningDayStatus,
        goal: LearningGoal? = nil
        
    ) {
        self.date = date
        self.status = status
        self.goal = goal
        self.recordedAt = date
    }
}
