import SwiftUI
import SwiftData


struct OnboardingView:View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()
    @State private var showsSaveError = false
    @State private var selectedGoal: LearningGoal?
    @State private var hasRestoredGoal = false
    @Query(sort: \LearningGoal.startDate, order: .reverse)
    private var savedGoals: [LearningGoal]

    var body: some View{
        ZStack{
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 80)
                
                Text("Hello **Learner**")
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
                
                Text("This app will help you learn everyday!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("I want to learn")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.primary)

                    TextField("Swift", text: $viewModel.preferences.topic)
                        .foregroundStyle(.primary)

                    Divider()
                }
                .padding(.top, 38)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("I want to learn it in a")
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        Group {
                            if viewModel.preferences.duration == .week {
                                Button("Week") {
                                    viewModel.preferences.duration = .week
                                }
                                .buttonStyle(.glassProminent)
                                .tint(.orange)
                            } else {
                                Button {
                                    viewModel.preferences.duration = .week
                                } label: {
                                    Text("Week")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.glass)
                            }
                        }
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        
                        Group {
                            if viewModel.preferences.duration == .month {
                                Button("Month") {
                                    viewModel.preferences.duration = .month
                                }
                                .buttonStyle(.glassProminent)
                                .tint(.orange)
                            } else {
                                Button {
                                    viewModel.preferences.duration = .month
                                } label: {
                                    Text("Month")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.glass)
                            }
                        }
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        
                        
                        Group {
                            if viewModel.preferences.duration == .year {
                                Button("Year") {
                                    viewModel.preferences.duration = .year
                                }
                                .buttonStyle(.glassProminent)
                                .tint(.orange)
                            } else {
                                Button {
                                    viewModel.preferences.duration = .year
                                } label: {
                                    Text("Year")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.glass)
                            }
                        }
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        
                        
                        
                        }
              
                }
                .padding(.top, 24)

                Spacer(minLength: 32)

                VStack(spacing: 12) {
                    Group {
                        if viewModel.canStartLearning {
                            Button("Start Learning") {
                                
                                guard let goal = viewModel.makeGoal() else {
                                    showsSaveError = true
                                    return
                                }

                                modelContext.insert(goal)

                                do {
                                    try modelContext.save()
                                    selectedGoal = goal
                                } catch {
                                    modelContext.delete(goal)
                                    showsSaveError = true
                                }
                                
                            }
                            .buttonStyle(.glassProminent)
                            .tint(.orange)
                        } else {
                            Button {
                            } label: {
                                Text("Start Learning")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.glass)
                            .disabled(true)
                        }
                    }
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                    
                    Text("You can edit your desire later")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)
                .alert("Couldn’t save goal", isPresented: $showsSaveError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Please try again.")
                }
                
                .fullScreenCover(item: $selectedGoal) { goal in
                    GoalView(goal: goal)
                }
                .task {
                    guard !hasRestoredGoal else { return }
                    hasRestoredGoal = true
                    selectedGoal = savedGoals.first
                }
                
            }
            .padding()
            .padding(.top, 24)
            
            
        }
        
        
        
        
        
        
        
    }
    
    
    
}

 #Preview {
    OnboardingView()
         .modelContainer(
                 for: [LearningGoal.self, LearningDay.self],
                 inMemory: true
             )
}

//  LearningApp.swift
//  LearningApp
//
//  Created by Shaima Basaleh on 29/05/1448 AH.
//

