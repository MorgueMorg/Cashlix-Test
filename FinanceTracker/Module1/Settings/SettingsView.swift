import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var goalStore: GoalStore

    @State private var showBudgetEditor     = false
    @State private var showClearDataAlert   = false
    @State private var showClearGoalsAlert  = false
    @State private var showTipsSheet        = false
    @State private var showRatePopup        = false
    @State private var notificationsEnabled = false
    @State private var dailyReminderTime    = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()

    var body: some View {
        NavigationView {
            List {
                // MARK: Appearance
                Section {
                    ForEach(ColorSchemePreference.allCases) { pref in
                        Button {
                            withAnimation { settings.colorScheme = pref }
                        } label: {
                            HStack {
                                Label {
                                    Text(pref.label)
                                        .foregroundColor(.primary)
                                } icon: {
                                    Image(systemName: pref.icon)
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                                if settings.colorScheme == pref {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }

                // MARK: Currency
                Section {
                    ForEach(AppSettings.currencies, id: \.code) { cur in
                        Button {
                            settings.currencyCode = cur.code
                        } label: {
                            HStack {
                                Text(cur.flag).font(.title3)
                                Text("\(cur.code) — \(cur.name)")
                                    .foregroundColor(.primary)
                                Spacer()
                                if settings.currencyCode == cur.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Label("Currency", systemImage: "dollarsign.circle.fill")
                }

                // MARK: Budget
                Section {
                    HStack {
                        Label("Monthly Budget", systemImage: "target")
                        Spacer()
                        Text(settings.monthlyBudget > 0
                             ? settings.formatAmount(settings.monthlyBudget)
                             : "Not Set")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showBudgetEditor = true }

                    if settings.monthlyBudget > 0 {
                        let used  = store.monthlyExpenses
                        let ratio = min(used / settings.monthlyBudget, 1.0)
                        let color: Color = ratio < 0.75 ? .green : ratio < 1.0 ? .orange : .red
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("This Month")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(ratio * 100))% used")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(color)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 7)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(color)
                                        .frame(width: geo.size.width * CGFloat(ratio), height: 7)
                                }
                            }
                            .frame(height: 7)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label("Budget", systemImage: "creditcard.fill")
                } footer: {
                    Text("Track your monthly spending against a set limit.")
                }

                // MARK: Notifications (UI only - no actual scheduling)
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Daily Reminder", systemImage: "bell.fill")
                    }
                    if notificationsEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $dailyReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Label("Notifications", systemImage: "bell.badge.fill")
                } footer: {
                    Text("Get a daily nudge to log your transactions.")
                }

                // MARK: Quick Tips
                Section {
                    Button {
                        showTipsSheet = true
                    } label: {
                        Label("Financial Tips", systemImage: "lightbulb.fill")
                    }
                    Button {
                        showRatePopup = true
                    } label: {
                        Label("How to Read Reports", systemImage: "book.fill")
                    }
                } header: {
                    Label("Learn", systemImage: "graduationcap.fill")
                }

                // MARK: Data
                Section {
                    HStack {
                        Label("Transactions", systemImage: "tray.full.fill")
                        Spacer()
                        Text("\(store.transactions.count) records")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    HStack {
                        Label("Goals", systemImage: "flag.fill")
                        Spacer()
                        Text("\(goalStore.goals.count) goals")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    Button(role: .destructive) {
                        showClearDataAlert = true
                    } label: {
                        Label("Clear All Transactions", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                    Button(role: .destructive) {
                        showClearGoalsAlert = true
                    } label: {
                        Label("Clear All Goals", systemImage: "flag.slash.fill")
                            .foregroundColor(.red)
                    }
                } header: {
                    Label("Data", systemImage: "externaldrive.fill")
                } footer: {
                    Text("Clearing data is irreversible.")
                }

                // MARK: About
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Built with", systemImage: "swift")
                        Spacer()
                        Text("SwiftUI + UIKit")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                } header: {
                    Label("About Cashlix", systemImage: "app.badge.fill")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showBudgetEditor) {
                BudgetEditorSheet()
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showTipsSheet) {
                FinancialTipsSheet()
            }
            .sheet(isPresented: $showRatePopup) {
                ReportsGuideSheet()
            }
            .confirmationDialog(
                "Clear all transactions?",
                isPresented: $showClearDataAlert,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) { store.clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(store.transactions.count) transaction records.")
            }
            .confirmationDialog(
                "Clear all goals?",
                isPresented: $showClearGoalsAlert,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) { goalStore.clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(goalStore.goals.count) goals and their history.")
            }
        }
    }
}

// MARK: - Budget Editor Sheet

struct BudgetEditorSheet: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var budgetText = ""
    @State private var showError  = false

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    Text("Monthly Budget")
                        .font(.title2).fontWeight(.bold)
                    Text("Set a limit for your monthly spending.")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(settings.currencyCode)
                        .font(.title2).foregroundColor(.secondary)
                    TextField("0.00", text: $budgetText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 44, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                }
                if showError {
                    Text("Please enter a valid amount.")
                        .font(.caption).foregroundColor(.red)
                }
                VStack(spacing: 12) {
                    Button {
                        saveBudget()
                    } label: {
                        Text("Save Budget")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    if settings.monthlyBudget > 0 {
                        Button(role: .destructive) {
                            settings.monthlyBudget = 0
                            dismiss()
                        } label: {
                            Text("Remove Budget")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if settings.monthlyBudget > 0 {
                    budgetText = String(format: "%.2f", settings.monthlyBudget)
                }
            }
        }
    }

    private func saveBudget() {
        let cleaned = budgetText.replacingOccurrences(of: ",", with: ".")
        guard let val = Double(cleaned), val > 0 else { showError = true; return }
        settings.monthlyBudget = val
        dismiss()
    }
}

// MARK: - Financial Tips Sheet

struct FinancialTipsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let tips: [(icon: String, color: Color, title: String, body: String)] = [
        ("50.circle.fill",    .blue,   "50/30/20 Rule",
         "Allocate 50% of income to needs, 30% to wants, and 20% to savings & investments."),
        ("calendar.badge.clock", .orange, "Pay Yourself First",
         "Transfer your savings target immediately on payday, before spending on anything else."),
        ("chart.line.uptrend.xyaxis", .green, "Compound Interest",
         "Money invested early grows exponentially. Even small monthly contributions become significant over time."),
        ("creditcard.fill",  .red,    "Avoid Lifestyle Inflation",
         "When income rises, resist upgrading your lifestyle proportionally. Increase savings instead."),
        ("umbrella.fill",    .teal,   "Emergency Fund",
         "Build 3–6 months of expenses as a safety net before making any investments."),
        ("magnifyingglass",  .purple, "Track Every Expense",
         "Small recurring expenses (coffee, subscriptions) can add up to hundreds per month unnoticed."),
    ]

    var body: some View {
        NavigationView {
            List(tips.indices, id: \.self) { i in
                let tip = tips[i]
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(tip.color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: tip.icon)
                            .font(.system(size: 18))
                            .foregroundColor(tip.color)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.headline)
                        Text(tip.body)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Financial Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Reports Guide Sheet

struct ReportsGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let items: [(icon: String, color: Color, title: String, desc: String)] = [
        ("arrow.down.circle.fill",    .green,  "Income",        "Total money received in the selected period."),
        ("arrow.up.circle.fill",      .red,    "Expenses",      "Total money spent. Organized by category."),
        ("plusminus",                 .blue,   "Net / Balance", "Income minus expenses. Positive means you saved money."),
        ("percent",                   .orange, "Savings Rate",  "Percentage of income saved. Target: at least 20%."),
        ("chart.bar.xaxis",           .purple, "Monthly Trend", "6-month bars showing your income and spending over time."),
        ("chart.pie.fill",            .teal,   "Categories",    "Which areas consume the most of your spending budget."),
    ]

    var body: some View {
        NavigationView {
            List(items.indices, id: \.self) { i in
                let item = items[i]
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(item.color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: item.icon)
                            .font(.system(size: 18))
                            .foregroundColor(item.color)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.headline)
                        Text(item.desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Reading Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
