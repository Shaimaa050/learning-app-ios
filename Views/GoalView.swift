import SwiftUI
import SwiftData

struct GoalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showsSaveError = false
    @Environment(\.dismiss) private var dismiss
    @State private var showsActivities = false
    @State private var showsEditGoal = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentDate = Date()
    
    let goal: LearningGoal
    private var weekDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 1

        guard let weekStart = calendar.dateInterval(
            of: .weekOfYear,
            for: currentDate
        )?.start else {
            return []
        }

        return (0..<7).compactMap { offset in
            calendar.date(
                byAdding: .day,
                value: offset,
                to: weekStart
            )
        }
    }
    
    private var activeDays: [LearningDay] {
        goal.days.filter {
            $0.recordedAt >= goal.streakStartDate
        }
    }
    
    private var todayRecord: LearningDay? {
        guard let date = recordingDate else {
            return nil
        }

        return activeDays.first {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        
        
    }

    private var freezesUsed: Int {
        activeDays.filter { $0.status == .frozen }.count
    }

    private var canRecordToday: Bool {
        recordingDate != nil
    }

    private func recordToday(as status: LearningDayStatus) {
        currentDate = Date()
        guard let targetDate = recordingDate else { return }

        let existingDay = todayRecord

        guard existingDay?.status != status else { return }

        if status == .frozen {
            guard freezesUsed < goal.duration.freezeLimit else {
                return
            }
        }

        if let day = existingDay {
            // نغي حالة اليوم الموجود بدل إضافة يوم آخر.
            let previousStatus = day.status
            day.status = status

            do {
                try modelContext.save()
            } catch {
                day.status = previousStatus
                showsSaveError = true
            }
        } else {
            let day = LearningDay(
                date: targetDate,
                status: status
            )

            day.recordedAt = Date()

            modelContext.insert(day)
            goal.days.append(day)

            do {
                try modelContext.save()
            } catch {
                goal.days.removeAll { $0 === day }
                modelContext.delete(day)
                showsSaveError = true
            }
        }
    }
    
    private func status(for date: Date) -> LearningDayStatus? {
        activeDays.first { day in
            Calendar.current.isDate(day.date, inSameDayAs: date)
        }?.status
    }
    
    
    private var hasBrokenStreak: Bool {
        if goal.hasFailed { return true }
        if goal.isCompleted { return false }

        let calendar = Calendar.current
        let now = currentDate
        var day = calendar.startOfDay(for: goal.streakStartDate)

        while day < goal.endDate {
            guard let deadline = calendar.date(
                byAdding: .hour,
                value: 32,
                to: day
            ) else {
                return false
            }

            // هذا اليوم والأيام التالية ما انتهت مهلتها.
            guard now > deadline else {
                return false
            }

            let wasRecordedOnTime = activeDays.contains { record in
                calendar.isDate(record.date, inSameDayAs: day)
                    && record.recordedAt <= deadline
            }

            if !wasRecordedOnTime {
                return true
            }

            guard let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: day
            ) else {
                return false
            }

            day = nextDay
        }

        return false
    }
    
    
    private var recordingDate: Date? {
        guard !goal.isCompleted, !goal.hasFailed, !hasBrokenStreak else {
            return nil
        }

        let calendar = Calendar.current
        let now = currentDate
        let today = calendar.startOfDay(for: now)
        let firstDay = calendar.startOfDay(for: goal.streakStartDate)

        if let yesterday = calendar.date(
            byAdding: .day,
            value: -1,
            to: today
        ),
           yesterday >= firstDay,
           yesterday < goal.endDate,
           let deadline = calendar.date(
               byAdding: .hour,
               value: 32,
               to: yesterday
           ),
           now <= deadline {

            let yesterdayIsRecorded = activeDays.contains {
                calendar.isDate($0.date, inSameDayAs: yesterday)
            }

            if !yesterdayIsRecorded {
                return yesterday
            }
        }

        guard today >= firstDay, today < goal.endDate else {
            return nil
        }

        return today
    }
    
    private var hasReachedGoal: Bool {
        if goal.isCompleted { return true }
        if goal.hasFailed { return false }

        guard currentDate >= goal.endDate, !hasBrokenStreak else {
            return false
        }

        let calendar = Calendar.current
        var day = calendar.startOfDay(for: goal.streakStartDate)

        while day < goal.endDate {
            guard let deadline = calendar.date(
                byAdding: .hour,
                value: 32,
                to: day
            ) else {
                return false
            }

            let isRecorded = activeDays.contains { record in
                calendar.isDate(record.date, inSameDayAs: day)
                    && record.recordedAt <= deadline
            }

            guard isRecorded else {
                return false
            }

            guard let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: day
            ) else {
                return false
            }

            day = nextDay
        }

        return true
    }
    
    private func saveGoalResultIfNeeded() {
        guard !goal.isCompleted, !goal.hasFailed else {
            return
        }

        let failed = hasBrokenStreak
        let succeeded = !failed && hasReachedGoal

        guard failed || succeeded else {
            return
        }

        goal.isCompleted = succeeded
        goal.hasFailed = failed

        do {
            try modelContext.save()
        } catch {
            goal.isCompleted = false
            goal.hasFailed = false
            showsSaveError = true
        }
    }

    private var goalResultView: some View {
        VStack(spacing: 12) {
            Image(
                systemName: hasReachedGoal
                    ? "hands.clap.fill"
                    : "xmark.seal.fill"
            )
            .font(.system(size: 40))
            .foregroundStyle(.orange)
            .accessibilityHidden(true)

            Text(
                hasReachedGoal
                    ? "Well done!"
                    : "You didn't reach your goal this time."
            )
            .font(.headline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)

            Text(
                hasReachedGoal
                    ? "Ready for your next goal?"
                    : "Want to set another goal?"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button {
                dismiss()
            } label: {
                Label("Set a goal", systemImage: "pencil.and.outline")
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.top, 64)
        }
        .frame(maxWidth: .infinity)
    }
    
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Activity")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)
                        
                        Text(
                            currentDate,
                            format: .dateTime
                                .weekday(.wide)
                                .day()
                                .month(.wide)
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showsActivities = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .frame(minWidth: 24, minHeight: 24)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .accessibilityLabel("Activities calendar")
                    
                    Button {
                        showsEditGoal = true
                    } label: {
                        Image(systemName: "pencil.and.outline")
                            .font(.title2)
                            .frame(minWidth: 24, minHeight: 24)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .accessibilityLabel("Edit goal")
                }
                .foregroundStyle(.primary)
                
                HStack(spacing: 0) {
                    ForEach(weekDates, id: \.self) { date in
                        VStack(spacing: 0) {
                            Text(date, format: .dateTime.weekday(.narrow))
                                .font(.caption)
                                .foregroundStyle(.primary)
                            
                            Text(date, format: .dateTime.day())
                                .font(.title3)
                                .foregroundStyle(
                                    status(for: date) == .learned
                                    ? Color.orange
                                    : status(for: date) == .frozen
                                    ? Color.cyan
                                    : Calendar.current.isDate(date, inSameDayAs: currentDate)
                                    ? Color.white
                                    : Color.primary
                                )
                                .frame(minWidth: 40, minHeight: 40)
                                .background {
                                    if let dayStatus = status(for: date) {
                                        Circle()
                                            .fill(
                                                dayStatus == .learned
                                                ? Color.orange.opacity(0.15)
                                                : Color.cyan.opacity(0.15)
                                            )
                                    } else if Calendar.current.isDate(date, inSameDayAs: currentDate) {
                                        Circle()
                                            .fill(.orange)
                                    }
                                }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 16)
                
                HStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        
                        Text("\(activeDays.filter { $0.status == .learned }.count) days")
                            .font(.headline)
                        
                        Text("Learned")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .glassEffect(
                        .regular,
                        in: RoundedRectangle(cornerRadius: 28)
                    )
                    
                    VStack(spacing: 8) {
                        Image(systemName: "snowflake")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        
                        Text("\(activeDays.filter { $0.status == .frozen }.count) days")
                            .font(.headline)
                        
                        Text("Freezed")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .glassEffect(
                        .regular,
                        in: RoundedRectangle(cornerRadius: 28)
                    )
                }
                .padding(.top, 12)
                
                Spacer(minLength: 48)
                
                if hasReachedGoal || hasBrokenStreak {
                    goalResultView
                    
                    Spacer(minLength: 24)
                } else {
                    
                    Button {
                        recordToday(as: .learned)
                    } label: {
                        Text(
                            todayRecord?.status == .learned
                            ? "Logged as Learned"
                            : "Log as Learned"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    }
                    .modifier(
                        ActivityButtonStyle(
                            isSelected: todayRecord?.status == .learned,
                            color: .orange
                        )
                    )
                    .buttonBorderShape(.circle)
                    .frame(maxWidth: 300)
                    .frame(maxWidth: .infinity)
                    .disabled(
                        !canRecordToday || todayRecord?.status == .learned
                    )
                    
                    Spacer(minLength: 24)
                    
                    VStack(spacing: 16) {
                        Button {
                            recordToday(as: .frozen)
                        } label: {
                            Text(
                                todayRecord?.status == .frozen
                                ? "Freezed for a day"
                                : "Freeze for a day"
                            )
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                        }
                        .modifier(
                            ActivityButtonStyle(
                                isSelected: todayRecord?.status == .frozen,
                                color: .cyan
                            )
                        )
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .disabled(
                            !canRecordToday
                            || todayRecord?.status == .frozen
                            || freezesUsed >= goal.duration.freezeLimit
                        )
                        
                        Text(
                            "\(freezesUsed) out of \(goal.duration.freezeLimit) Freezes used"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: 300)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 16)
                        .padding(.top, 12)
                    } // نهاية ZStack
                    .alert("Couldn’t save activity", isPresented: $showsSaveError) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("Please try again.")
                    }
                    .fullScreenCover(isPresented: $showsActivities) {
                        ActivitiesView()
                    }
                    .fullScreenCover(isPresented: $showsEditGoal) {
                        EditGoalView(goal: goal)
                    }
                    .task(id: scenePhase) {
                        guard scenePhase == .active else { return }

                        while !Task.isCancelled {
                            currentDate = Date()
                            if !showsEditGoal && !showsSaveError {
                                saveGoalResultIfNeeded()
                            }

                            do {
                                try await Task.sleep(for: .seconds(1))
                            } catch {
                                return
                            }
                        }
                    }
                } // نهاية body
            } // نهاية GoalView

private struct ActivityButtonStyle: ViewModifier {
    let isSelected: Bool
    let color: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if isSelected {
            content
                .buttonStyle(.glass)
                .tint(.primary)
        }  else {
            content
                .buttonStyle(.glassProminent)
                .tint(color)
                .foregroundStyle(.white)
        }
    }
}


#Preview {
    GoalView(
        goal: LearningGoal(
            topic: "Swift",
            duration: .week,
            startDate: .now,
            endDate: .now.addingTimeInterval(7 * 24 * 60 * 60)
        )
    )
}
