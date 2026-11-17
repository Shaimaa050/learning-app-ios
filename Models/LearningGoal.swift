import Foundation
import SwiftData

@Model
final class LearningGoal {
    var topic: String
    var duration: LearningDuration
    var startDate: Date
    var endDate: Date
    var isCompleted: Bool
    var hasFailed: Bool = false
    @Relationship(inverse: \LearningDay.goal)
    var days: [LearningDay] = []
    var streakStartDate: Date
    
    init(
        topic: String,
        duration: LearningDuration,
        startDate: Date,
        endDate: Date
        
    ) {
        self.streakStartDate = startDate
        self.topic = topic
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.isCompleted = false
    }
}


