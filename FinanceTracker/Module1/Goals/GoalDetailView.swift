import SwiftUI

struct GoalDetailView: View {
    let goal: FinancialGoal
    @EnvironmentObject var goalStore: GoalStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showContribution = false
    @State private var showEditGoal     = false
    @State private var showDeleteAlert  = false
    @State private var contribAmount    = ""
    @State private var contribNote      = ""
    @State private var showContribError = false

    // Live data from store
    private var liveGoal: FinancialGoal {
        goalStore.goals.first { $0.id == goal.id } ?? goal
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    statsGrid
                    if let monthly = liveGoal.monthlyRequired {
                        insightBanner(monthly: monthly)
                    }
                    addMoneyButton
                    contributionHistory
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(liveGoal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showEditGoal = true } label: {
                            Label("Edit Goal", systemImage: "pencil")
                        }
                        Button(role: .destructive) { showDeleteAlert = true } label: {
                            Label("Delete Goal", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showEditGoal) {
                EditGoalSheet(goal: liveGoal)
                    .environmentObject(goalStore)
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showContribution) {
                addContributionSheet
            }
            .confirmationDialog(
                "Delete \"\(liveGoal.name)\"?",
                isPresented: $showDeleteAlert,
                titleVisibility: .visible
            ) {
                Button("Delete Goal", role: .destructive) {
                    goalStore.delete(liveGoal)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: Hero Card

    private var heroCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(liveGoal.color.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: liveGoal.icon.sfSymbol)
                    .font(.system(size: 34))
                    .foregroundColor(liveGoal.color.color)
            }

            VStack(spacing: 4) {
                if liveGoal.isCompleted {
                    Label("Goal Reached!", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Text(settings.formatAmount(liveGoal.remaining) + " remaining")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("\(settings.formatAmount(liveGoal.currentAmount)) of \(settings.formatAmount(liveGoal.targetAmount))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [liveGoal.color.color.opacity(0.7), liveGoal.color.color],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(geo.size.width * CGFloat(liveGoal.progress), 0),
                                height: 14
                            )
                    }
                }
                .frame(height: 14)
                Text("\(Int(liveGoal.progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }

    // MARK: Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCell(icon: "target",        title: "Target",       value: settings.formatAmount(liveGoal.targetAmount), color: liveGoal.color.color)
            statCell(icon: "checkmark.circle.fill", title: "Saved", value: settings.formatAmount(liveGoal.currentAmount), color: .green)
            if let dl = liveGoal.deadline {
                let daysLeft = liveGoal.daysLeft ?? 0
                statCell(
                    icon: "calendar",
                    title: "Deadline",
                    value: dl.formatted(.dateTime.month(.abbreviated).day().year()),
                    color: daysLeft < 14 ? .red : .blue
                )
            }
            statCell(
                icon: "arrow.up.doc.fill",
                title: "Contributions",
                value: "\(liveGoal.contributions.count)",
                color: .purple
            )
        }
    }

    private func statCell(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: Insight Banner

    private func insightBanner(monthly: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.title3)
            Text("Save **\(settings.formatAmount(monthly))** per month to reach your goal on time.")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(14)
    }

    // MARK: Add Money Button

    private var addMoneyButton: some View {
        Button { showContribution = true } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add Money")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(liveGoal.isCompleted ? Color.gray : liveGoal.color.color)
            .cornerRadius(16)
        }
        .disabled(liveGoal.isCompleted)
    }

    // MARK: Contribution History

    @ViewBuilder
    private var contributionHistory: some View {
        if !liveGoal.contributions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("History")
                        .font(.headline)
                    Spacer()
                    Text("\(liveGoal.contributions.count) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                ForEach(liveGoal.contributions.reversed()) { c in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.note.isEmpty ? "Added funds" : c.note)
                                .font(.subheadline)
                            Text(c.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("+" + settings.formatAmount(c.amount))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 6)
                    if c.id != liveGoal.contributions.first?.id {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }

    // MARK: Add Contribution Sheet

    private var addContributionSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(liveGoal.color.color.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: liveGoal.icon.sfSymbol)
                        .font(.system(size: 32))
                        .foregroundColor(liveGoal.color.color)
                }

                VStack(spacing: 8) {
                    Text("Add funds to \(liveGoal.name)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("\(settings.formatAmount(liveGoal.remaining)) remaining")
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 12) {
                    TextField("Amount", text: $contribAmount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .padding(.horizontal)

                    TextField("Note (optional)", text: $contribNote)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .padding(.horizontal)
                }

                // Quick amount buttons
                HStack(spacing: 12) {
                    ForEach([50, 100, 500, 1000], id: \.self) { val in
                        Button {
                            contribAmount = "\(val)"
                        } label: {
                            Text("+\(val)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(liveGoal.color.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(liveGoal.color.color.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }

                if showContribError {
                    Text("Enter a valid amount")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button {
                    saveContribution()
                } label: {
                    Text("Confirm")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(liveGoal.color.color)
                        .cornerRadius(16)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .dismissKeyboardOnTap()
            .keyboardDoneToolbar()
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        contribAmount = ""
                        contribNote   = ""
                        showContribution = false
                    }
                }
            }
        }
    }

    private func saveContribution() {
        let cleaned = contribAmount.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else {
            showContribError = true
            return
        }
        goalStore.addContribution(to: liveGoal.id, amount: amount, note: contribNote)
        contribAmount    = ""
        contribNote      = ""
        showContribError = false
        showContribution = false
    }
}

// MARK: - Edit Goal Sheet

struct EditGoalSheet: View {
    let goal: FinancialGoal
    @EnvironmentObject var goalStore: GoalStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var targetText: String
    @State private var selectedIcon: GoalIcon
    @State private var selectedColor: GoalColor
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var noteText: String
    @State private var showError = false

    init(goal: FinancialGoal) {
        self.goal = goal
        _name          = State(initialValue: goal.name)
        _targetText    = State(initialValue: String(format: "%.2f", goal.targetAmount))
        _selectedIcon  = State(initialValue: goal.icon)
        _selectedColor = State(initialValue: goal.color)
        _hasDeadline   = State(initialValue: goal.deadline != nil)
        _deadline      = State(initialValue: goal.deadline ?? Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date())
        _noteText      = State(initialValue: goal.note)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Goal Info") {
                    TextField("Goal Name", text: $name)
                    TextField("Target Amount", text: $targetText)
                        .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: $noteText)
                }
                Section("Appearance") {
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(GoalIcon.allCases, id: \.rawValue) { icon in
                            Label(icon.label, systemImage: icon.sfSymbol).tag(icon)
                        }
                    }
                    HStack {
                        Text("Color")
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(GoalColor.allCases, id: \.rawValue) { c in
                                Button {
                                    selectedColor = c
                                } label: {
                                    Circle()
                                        .fill(c.color)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == c ? 2 : 0)
                                        )
                                        .shadow(color: c.color.opacity(0.4), radius: selectedColor == c ? 3 : 0)
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
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { saveEdit() } label: {
                        Text("Save").fontWeight(.semibold)
                    }
                }
            }
            .alert("Invalid Input", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please fill in the goal name and a valid target amount.")
            }
            .keyboardDoneToolbar()
        }
    }

    private func saveEdit() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let amount = Double(targetText.replacingOccurrences(of: ",", with: ".")),
              amount > 0
        else { showError = true; return }

        var updated        = goal
        updated.name         = name.trimmingCharacters(in: .whitespaces)
        updated.targetAmount = amount
        updated.icon         = selectedIcon
        updated.color        = selectedColor
        updated.deadline     = hasDeadline ? deadline : nil
        updated.note         = noteText
        goalStore.update(updated)
        dismiss()
    }
}
