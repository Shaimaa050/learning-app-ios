import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \LearningGoal.startDate)
    private var goals: [LearningGoal]

    
    private var months: [Date] {
        let calendar = Calendar.current

        let allStartDates = goals.map(\.startDate)
            + goals.flatMap(\.days).map(\.date)

        let firstDate = allStartDates.min() ?? Date.now
        
        let lastDate = max(
            goals.map(\.endDate).max() ?? Date.now,
            Date.now
        )

        guard let firstMonth = calendar.dateInterval(
            of: .month,
            for: firstDate
        )?.start,
        let lastMonth = calendar.dateInterval(
            of: .month,
            for: lastDate
        )?.start else {
            return []
        }

        var result: [Date] = []
        var month = firstMonth

        while month <= lastMonth {
            result.append(month)

            guard let nextMonth = calendar.date(
                byAdding: .month,
                value: 1,
                to: month
            ) else {
                break
            }

            month = nextMonth
        }

        return result
    }
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        return calendar
    }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 0),
        count: 7
    )

    private func dates(in month: Date) -> [Date] {
        guard let range = calendar.range(
            of: .day,
            in: .month,
            for: month
        ) else {
            return []
        }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month)
        }
    }

    private func leadingSpaces(for month: Date) -> Int {
        (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
    }

    private func status(for date: Date) -> LearningDayStatus? {
        goals
            .flatMap(\.days)
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .max { $0.recordedAt < $1.recordedAt }?
            .status
    }

    private func dayColor(for date: Date) -> Color {
        switch status(for: date) {
        case .learned:
            return .orange
        case .frozen:
            return .cyan
        case nil:
            return calendar.isDateInToday(date) ? .white : .primary
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(months, id: \.self) { month in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(month, format: .dateTime.month(.wide).year())
                                .font(.headline)
                                .padding(.horizontal, 8)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(0..<7, id: \.self) { index in
                                    Text(calendar.shortWeekdaySymbols[index])
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }

                                ForEach(0..<leadingSpaces(for: month), id: \.self) { _ in
                                    Color.clear
                                        .frame(height: 40)
                                }

                                ForEach(dates(in: month), id: \.self) { date in
                                    Text(date, format: .dateTime.day())
                                        .font(.title3)
                                        .foregroundStyle(dayColor(for: date))
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .background {
                                            if let dayStatus = status(for: date) {
                                                Circle()
                                                    .fill(
                                                        dayStatus == .learned
                                                            ? Color.orange.opacity(0.15)
                                                            : Color.cyan.opacity(0.15)
                                                    )
                                                    .frame(width: 38, height: 38)
                                            } else if calendar.isDateInToday(date) {
                                                Circle()
                                                    .fill(.orange)
                                                    .frame(width: 38, height: 38)
                                            }
                                        }
                                }
                            }

                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Activities")
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
            }
        }
    }
}
#Preview {
    ActivitiesView()
        .modelContainer(
            for: [LearningGoal.self, LearningDay.self],
            inMemory: true
        )
}
