import SwiftUI

struct AddTransactionSheet: View {
    @EnvironmentObject var store: TransactionStore
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var type: TransactionType = .expense
    @State private var category: TransactionCategory = .food
    @State private var note = ""
    @State private var date = Date()
    @State private var showValidationError = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Amount")) {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(header: Text("Type")) {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.title).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(TransactionCategory.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                }

                Section(header: Text("Details")) {
                    TextField("Note (optional)", text: $note)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
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
            .alert("Enter a valid amount greater than 0", isPresented: $showValidationError) {
                Button("OK") {}
            }
        }
    }

    private func save() {
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0 else {
            showValidationError = true
            return
        }
        store.add(Transaction(amount: value, type: type, category: category, note: note, date: date))
        dismiss()
    }
}
