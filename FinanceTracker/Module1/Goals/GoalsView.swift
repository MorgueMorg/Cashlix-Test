import SwiftUI

// MARK: - Goals Tab Root

struct GoalsView: View {
    @EnvironmentObject var goalStore: GoalStore
    @EnvironmentObject var settings: AppSettings

    @State private var showAddGoal  = false
    @State private var selectedGoal: FinancialGoal?

    var body: some View {
        NavigationView {
            Group {
                if goalStore.goals.isEmpty {
                    goalsEmptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            goalsSummaryCard
                            if !goalStore.activeGoals.isEmpty {
                                sectionLabel("Active", count: goalStore.activeGoals.count)
                                ForEach(goalStore.activeGoals) { goal in
                                    GoalCard(goal: goal)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedGoal = goal }
                                }
                            }
                            if !goalStore.completedGoals.isEmpty {
                                sectionLabel("Completed 🎉", count: goalStore.completedGoals.count)
                                ForEach(goalStore.completedGoals) { goal in
                                    GoalCard(goal: goal)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedGoal = goal }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddGoal = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalSheet(isPresented: $showAddGoal)
                    .environmentObject(goalStore)
                    .environmentObject(settings)
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal)
                    .environmentObject(goalStore)
                    .environmentObject(settings)
            }
        }
    }

    // MARK: Summary Card

    private var goalsSummaryCard: some View {
        HStack(spacing: 0) {
            summaryMetric(
                title: "Saved",
                value: settings.formatAmount(goalStore.totalSaved),
                color: .green
            )
            Divider().frame(height: 40)
            summaryMetric(
                title: "Target",
                value: settings.formatAmount(goalStore.totalTarget),
                color: .blue
            )
            Divider().frame(height: 40)
            summaryMetric(
                title: "Done",
                value: "\(goalStore.completedCount)/\(goalStore.goals.count)",
                color: .orange
            )
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.top, 8)
    }

    private func summaryMetric(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Section Label

    private func sectionLabel(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue)
                .clipShape(Capsule())
        }
        .padding(.top, 4)
    }

    // MARK: Empty State

    private var goalsEmptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "flag.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.6))
            }
            Text("No Goals Yet")
                .font(.title2)
                .fontWeight(.bold)
            Text("Create financial goals to stay motivated\nand track your progress.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Button { showAddGoal = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Create First Goal")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(14)
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: FinancialGoal
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(goal.color.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: goal.icon.sfSymbol)
                        .font(.system(size: 20))
                        .foregroundColor(goal.color.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.name)
                        .font(.headline)
                        .lineLimit(1)
                    deadlineLabel
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(settings.formatAmount(goal.currentAmount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("of \(settings.formatAmount(goal.targetAmount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(goal.isCompleted ? Color.green : goal.color.color)
                            .frame(width: max(geo.size.width * CGFloat(goal.progress), 0), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    if goal.isCompleted {
                        Label("Goal reached!", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("\(settings.formatAmount(goal.remaining)) to go")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    @ViewBuilder
    private var deadlineLabel: some View {
        if goal.isCompleted {
            Label("Completed!", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
        } else if let days = goal.daysLeft {
            if days < 0 {
                Label("Overdue", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if days == 0 {
                Label("Due today", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if days <= 14 {
                Text("\(days) days left")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text("\(days) days left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            Text("No deadline")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var goalStore: GoalStore
    @EnvironmentObject var settings: AppSettings

    @State private var name: String        = ""
    @State private var targetText: String  = ""
    @State private var selectedIcon: GoalIcon   = .star
    @State private var selectedColor: GoalColor = .blue
    @State private var hasDeadline = false
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var noteText: String = ""
    @State private var showIconPicker = false
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                // Preview
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(selectedColor.color.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                Image(systemName: selectedIcon.sfSymbol)
                                    .font(.system(size: 30))
                                    .foregroundColor(selectedColor.color)
                            }
                            Text(name.isEmpty ? "Goal Name" : name)
                                .font(.headline)
                                .foregroundColor(name.isEmpty ? .secondary : .primary)
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                }

                Section("Goal Info") {
                    TextField("Goal Name (e.g. New Car)", text: $name)
                    TextField("Target Amount", text: $targetText)
                        .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: $noteText)
                }

                Section("Appearance") {
                    // Icon picker
                    Button {
                        showIconPicker.toggle()
                    } label: {
                        HStack {
                            Text("Icon")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: selectedIcon.sfSymbol)
                                .foregroundColor(selectedColor.color)
                            Text(selectedIcon.label)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if showIconPicker {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(GoalIcon.allCases, id: \.rawValue) { icon in
                                Button {
                                    selectedIcon = icon
                                    showIconPicker = false
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(selectedIcon == icon
                                                  ? selectedColor.color.opacity(0.2)
                                                  : Color(.systemGray6))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: icon.sfSymbol)
                                            .font(.system(size: 16))
                                            .foregroundColor(selectedIcon == icon ? selectedColor.color : .secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Color picker
                    HStack {
                        Text("Color")
                        Spacer()
                        HStack(spacing: 10) {
                            ForEach(GoalColor.allCases, id: \.rawValue) { c in
                                Button {
                                    selectedColor = c
                                } label: {
                                    Circle()
                                        .fill(c.color)
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == c ? 3 : 0)
                                        )
                                        .shadow(color: c.color.opacity(0.5), radius: selectedColor == c ? 4 : 0)
                                        .scaleEffect(selectedColor == c ? 1.15 : 1.0)
                                        .animation(.spring(response: 0.2), value: selectedColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Deadline") {
                    Toggle("Set a deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveGoal()
                    } label: {
                        Text("Save").fontWeight(.semibold)
                    }
                }
            }
            .alert("Missing Info", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a goal name and target amount.")
            }
            .keyboardDoneToolbar()
        }
    }

    private func saveGoal() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let amount = Double(targetText.replacingOccurrences(of: ",", with: ".")),
              amount > 0
        else {
            showError = true
            return
        }
        let goal = FinancialGoal(
            name:         name.trimmingCharacters(in: .whitespaces),
            targetAmount: amount,
            icon:         selectedIcon,
            color:        selectedColor,
            deadline:     hasDeadline ? deadline : nil,
            note:         noteText
        )
        goalStore.add(goal)
        isPresented = false
    }
}
