import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet    = false
    @State private var showDeleteAlert  = false
    @State private var showDuplicateToast = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    amountHero
                    detailsCard
                    actionsRow
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showEditSheet = true } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button { duplicateTransaction() } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        Divider()
                        Button(role: .destructive) { showDeleteAlert = true } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditTransactionSheet(transaction: transaction)
                    .environmentObject(store)
                    .environmentObject(settings)
            }
            .confirmationDialog(
                "Delete this transaction?",
                isPresented: $showDeleteAlert,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    store.delete(transaction)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .overlay(alignment: .bottom) {
                if showDuplicateToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Transaction duplicated")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .shadow(radius: 6)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: Amount Hero

    private var amountHero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(transaction.category.color)
            }
            Text((transaction.type == .income ? "+" : "-") + settings.formatAmount(transaction.amount))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(transaction.type == .income ? .green : .red)
            Label(transaction.type == .income ? "Income" : "Expense",
                  systemImage: transaction.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.subheadline)
                .foregroundColor(transaction.type.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(
                icon: transaction.category.icon,
                color: transaction.category.color,
                title: "Category",
                value: transaction.category.displayName
            )
            Divider().padding(.leading, 52)
            detailRow(
                icon: "calendar",
                color: .blue,
                title: "Date",
                value: transaction.date.formatted(.dateTime.month(.wide).day().year())
            )
            Divider().padding(.leading, 52)
            detailRow(
                icon: "clock",
                color: .orange,
                title: "Time",
                value: transaction.date.formatted(.dateTime.hour().minute())
            )
            if let note = transaction.note, !note.isEmpty {
                Divider().padding(.leading, 52)
                detailRow(
                    icon: "note.text",
                    color: .purple,
                    title: "Note",
                    value: note
                )
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func detailRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Actions Row

    private var actionsRow: some View {
        HStack(spacing: 12) {
            actionButton(icon: "pencil", label: "Edit", color: .blue) {
                showEditSheet = true
            }
            actionButton(icon: "doc.on.doc", label: "Duplicate", color: .orange) {
                duplicateTransaction()
            }
            actionButton(icon: "trash", label: "Delete", color: .red) {
                showDeleteAlert = true
            }
        }
    }

    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Duplicate

    private func duplicateTransaction() {
        var copy      = transaction
        copy.id       = UUID()
        copy.date     = Date()
        store.add(copy)
        withAnimation {
            showDuplicateToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showDuplicateToast = false
            }
        }
    }
}

// MARK: - Edit Transaction Sheet

struct EditTransactionSheet: View {
    let transaction: Transaction
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String
    @State private var type: TransactionType
    @State private var category: TransactionCategory
    @State private var note: String
    @State private var date: Date
    @State private var showError = false

    init(transaction: Transaction) {
        self.transaction = transaction
        _amountText = State(initialValue: String(format: "%.2f", transaction.amount))
        _type       = State(initialValue: transaction.type)
        _category   = State(initialValue: transaction.category)
        _note       = State(initialValue: transaction.note ?? "")
        _date       = State(initialValue: transaction.date)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Amount") {
                    HStack {
                        Text(settings.currencyCode)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.rawValue) { t in
                            Text(t.rawValue.capitalized).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(TransactionCategory.allCases, id: \.rawValue) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Note") {
                    TextField("Optional note", text: $note)
                }
            }
            .navigationTitle("Edit Transaction")
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
            .alert("Invalid Amount", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a valid amount greater than zero.")
            }
        }
    }

    private func saveEdit() {
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else {
            showError = true
            return
        }
        var updated    = transaction
        updated.amount   = amount
        updated.type     = type
        updated.category = category
        updated.note     = note.isEmpty ? nil : note
        updated.date     = date
        store.update(updated)
        dismiss()
    }
}
