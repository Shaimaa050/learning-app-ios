import SwiftUI
import SwiftData

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var topic: String
    @State private var duration: LearningDuration
    @State private var showsConfirmation = false
    @State private var showsSaveError = false

    let goal: LearningGoal

    init(goal: LearningGoal) {
        self.goal = goal
        _topic = State(initialValue: goal.topic)
        _duration = State(initialValue: goal.duration)
    }

    
    private func updateGoal() {
        let cleanTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let startDate = Calendar.current.startOfDay(for: now)

        guard !cleanTopic.isEmpty,
              let endDate = duration.endDate(from: startDate) else {
            showsSaveError = true
            return
        }

        let oldTopic = goal.topic
        let oldDuration = goal.duration
        let oldStartDate = goal.startDate
        let oldEndDate = goal.endDate
        let oldStreakStartDate = goal.streakStartDate
        let oldIsCompleted = goal.isCompleted
        let oldHasFailed = goal.hasFailed

        goal.topic = cleanTopic
        goal.duration = duration
        goal.startDate = startDate
        goal.endDate = endDate
        goal.streakStartDate = now
        goal.isCompleted = false
        goal.hasFailed = false

        do {
            try modelContext.save()
            dismiss()
        } catch {
            goal.topic = oldTopic
            goal.duration = oldDuration
            goal.startDate = oldStartDate
            goal.endDate = oldEndDate
            goal.streakStartDate = oldStreakStartDate
            goal.isCompleted = oldIsCompleted
            goal.hasFailed = oldHasFailed
            showsSaveError = true
        }
    }
    
     
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("I want to learn")

                    TextField("Swift", text: $topic)

                    Divider()
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("I want to learn it in a")

                    HStack(spacing: 12) {
                        durationButton("Week", value: .week)
                        durationButton("Month", value: .month)
                        durationButton("Year", value: .year)
                    }
                }

                Spacer()
            }
            .padding()
            .padding(.top, 32)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Learning Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Back")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsConfirmation = true
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.orange)
                    .buttonBorderShape(.circle)
                    .disabled(
                        topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || (topic == goal.topic && duration == goal.duration)
                    )
                    .accessibilityLabel("Save changes")
                }
            }
            
            .alert("Update goal", isPresented: $showsConfirmation) {
                Button("Dismiss", role: .cancel) {}

                Button("Update") {
                    updateGoal()
                }
            } message: {
                Text("If you update now, your streak will start over.")
            }
            .alert("Couldn’t update goal", isPresented: $showsSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again.")
            }
            
        }
        
    }

    @ViewBuilder
    private func durationButton(
        _ title: LocalizedStringKey,
        value: LearningDuration
    ) -> some View {
        if duration == value {
            Button(title) {
                duration = value
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)
            .controlSize(.large)
            .buttonBorderShape(.capsule)
        } else {
            Button {
                duration = value
            } label: {
                Text(title)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .buttonBorderShape(.capsule)
        }
    }
}
