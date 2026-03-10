import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: TransactionStore

    @State private var showClearConfirm = false
    @State private var showBudgetEditor = false
    @State private var budgetText = ""

    var body: some View {
        NavigationView {
            List {
                // MARK: Appearance
                Section(header: Text("Appearance")) {
                    ForEach(ColorSchemePreference.allCases) { pref in
                        HStack {
                            Image(systemName: pref.icon)
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text(pref.rawValue)
                            Spacer()
                            if settings.colorScheme == pref {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { settings.colorScheme = pref }
                    }
                }

                // MARK: Currency
                Section(header: Text("Currency")) {
                    ForEach(AppSettings.currencies) { option in
                        HStack {
                            Text(option.symbol)
                                .font(.headline)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.name).font(.subheadline)
                                Text(option.id).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            if settings.currencyCode == option.id {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { settings.currencyCode = option.id }
                    }
                }

                // MARK: Budget
                Section(header: Text("Monthly Budget")) {
                    Button {
                        budgetText = settings.monthlyBudget > 0
                            ? String(format: "%.2f", settings.monthlyBudget)
                            : ""
                        showBudgetEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            Text("Budget Limit")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(settings.monthlyBudget > 0
                                 ? settings.formatAmount(settings.monthlyBudget)
                                 : "Not set")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }

                // MARK: Data
                Section(header: Text("Data")) {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .foregroundColor(.blue).frame(width: 28)
                        Text("Total Transactions")
                        Spacer()
                        Text("\(store.transactions.count)").foregroundColor(.secondary)
                    }

                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill").frame(width: 28)
                            Text("Clear All Transactions")
                        }
                    }
                }

                // MARK: About
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue).frame(width: 28)
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Clear all transactions?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) { store.clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .sheet(isPresented: $showBudgetEditor) { budgetSheet }
        }
    }

    // MARK: - Budget sheet

    private var budgetSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Set monthly spending limit")) {
                    HStack {
                        Text(AppSettings.currencies
                            .first { $0.id == settings.currencyCode }?.symbol ?? "$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $budgetText)
                            .keyboardType(.decimalPad)
                    }
                }
                if settings.monthlyBudget > 0 {
                    Section {
                        Button("Remove Budget", role: .destructive) {
                            settings.monthlyBudget = 0
                            showBudgetEditor = false
                        }
                    }
                }
            }
            .navigationTitle("Monthly Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showBudgetEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveBudget) {
                        Text("Save").fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func saveBudget() {
        let cleaned = budgetText.replacingOccurrences(of: ",", with: ".")
        if let value = Double(cleaned), value > 0 {
            settings.monthlyBudget = value
        }
        showBudgetEditor = false
    }
}
