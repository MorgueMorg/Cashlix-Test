import SwiftUI

struct AddTransactionSheet: View {
    var presetType: TransactionType = .expense

    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var type: TransactionType
    @State private var category: TransactionCategory = .food
    @State private var note = ""
    @State private var date = Date()
    @State private var showError = false

    // Suggested quick amounts
    private let quickAmounts = [10, 25, 50, 100]

    init(presetType: TransactionType = .expense) {
        self.presetType = presetType
        _type = State(initialValue: presetType)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Amount entry hero
                amountHero
                    .padding(.vertical, 24)
                    .background(type == .income
                                ? Color.green.opacity(0.08)
                                : Color.red.opacity(0.08))

                // Form
                Form {
                    Section {
                        Picker("Type", selection: $type) {
                            ForEach(TransactionType.allCases, id: \.rawValue) { t in
                                Text(t.title).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: { Text("Type") }

                    Section {
                        Picker("Category", selection: $category) {
                            ForEach(TransactionCategory.allCases, id: \.rawValue) { c in
                                Label(c.displayName, systemImage: c.icon).tag(c)
                            }
                        }
                    } header: { Text("Category") }

                    Section {
                        TextField("Optional note…", text: $note)
                        DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    } header: { Text("Details") }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        Text("Save").fontWeight(.semibold)
                    }
                }
            }
            .alert("Invalid Amount", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a valid amount greater than zero.")
            }
        }
    }

    // MARK: - Amount Hero

    private var amountHero: some View {
        VStack(spacing: 16) {
            // Large amount input
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(settings.currencyCode)
                    .font(.title2)
                    .foregroundColor(.secondary)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(type == .income ? .green : .red)
                    .frame(maxWidth: 220)
            }

            // Quick amount buttons
            HStack(spacing: 10) {
                ForEach(quickAmounts, id: \.self) { val in
                    Button {
                        amountText = "\(val)"
                    } label: {
                        Text("+\(val)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(type == .income ? .green : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                (type == .income ? Color.green : Color.red).opacity(0.1)
                            )
                            .cornerRadius(10)
                    }
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0 else {
            showError = true
            return
        }
        store.add(Transaction(
            amount:   value,
            type:     type,
            category: category,
            note:     note.isEmpty ? nil : note,
            date:     date
        ))
        dismiss()
    }
}
