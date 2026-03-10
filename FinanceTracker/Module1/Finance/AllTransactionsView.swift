import SwiftUI

struct AllTransactionsView: View {
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings

    @State private var searchText   = ""
    @State private var filterType: FilterType  = .all
    @State private var filterCat:  TransactionCategory? = nil
    @State private var selectedTx: Transaction? = nil
    @State private var showCategoryFilter = false

    enum FilterType: String, CaseIterable {
        case all = "All"
        case income  = "Income"
        case expense = "Expense"
    }

    // MARK: - Filtered Transactions

    private var filtered: [Transaction] {
        store.transactions.filter { tx in
            let matchesSearch: Bool = {
                guard !searchText.isEmpty else { return true }
                let q = searchText.lowercased()
                return tx.category.displayName.lowercased().contains(q)
                    || (tx.note?.lowercased().contains(q) ?? false)
            }()
            let matchesType: Bool = {
                switch filterType {
                case .all:     return true
                case .income:  return tx.type == .income
                case .expense: return tx.type == .expense
                }
            }()
            let matchesCat: Bool = filterCat == nil || tx.category == filterCat
            return matchesSearch && matchesType && matchesCat
        }
    }

    // Group by day
    private var grouped: [(String, [Transaction])] {
        let cal = Calendar.current
        let now = Date()
        let grouped = Dictionary(grouping: filtered) { tx -> String in
            if cal.isDateInToday(tx.date)     { return "Today" }
            if cal.isDateInYesterday(tx.date) { return "Yesterday" }
            let days = cal.dateComponents([.day], from: tx.date, to: now).day ?? 0
            if days < 7                       { return "This Week" }
            return tx.date.formatted(.dateTime.month(.wide).year())
        }
        let order = ["Today", "Yesterday", "This Week"]
        let sortedKeys = grouped.keys.sorted { a, b in
            let ia = order.firstIndex(of: a) ?? Int.max
            let ib = order.firstIndex(of: b) ?? Int.max
            if ia != Int.max || ib != Int.max { return ia < ib }
            return a > b
        }
        return sortedKeys.map { key in (key, grouped[key] ?? []) }
    }

    var body: some View {
        ScrollView {
            // Filter bar
            VStack(spacing: 12) {
                filterTypeRow
                if showCategoryFilter { categoryFilterRow }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if filtered.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(grouped, id: \.0) { section in
                        transactionSection(header: section.0, items: section.1)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Search transactions...")
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation { showCategoryFilter.toggle() }
                } label: {
                    Image(systemName: filterCat == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .foregroundColor(filterCat == nil ? .primary : .blue)
                }
            }
        }
        .sheet(item: $selectedTx) { tx in
            TransactionDetailView(transaction: tx)
                .environmentObject(store)
                .environmentObject(settings)
        }
    }

    // MARK: Filter Type Row

    private var filterTypeRow: some View {
        HStack(spacing: 8) {
            ForEach(FilterType.allCases, id: \.rawValue) { ft in
                Button {
                    withAnimation { filterType = ft }
                } label: {
                    Text(ft.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(filterType == ft ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            filterType == ft ? Color.blue : Color(.secondarySystemGroupedBackground)
                        )
                        .cornerRadius(20)
                }
            }
            Spacer()
            Text("\(filtered.count) items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: Category Filter Row

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil, label: "All")
                ForEach(TransactionCategory.allCases, id: \.rawValue) { cat in
                    categoryChip(cat, label: cat.displayName)
                }
            }
        }
    }

    private func categoryChip(_ cat: TransactionCategory?, label: String) -> some View {
        let isSelected = filterCat == cat
        return Button {
            withAnimation { filterCat = cat }
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
        }
    }

    // MARK: Transaction Section

    private func transactionSection(header: String, items: [Transaction]) -> some View {
        Section {
            VStack(spacing: 0) {
                ForEach(items) { tx in
                    Button {
                        selectedTx = tx
                    } label: {
                        TxRowCompact(transaction: tx)
                            .foregroundColor(.primary)
                    }
                    if tx.id != items.last?.id {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .padding(.horizontal)
        } header: {
            HStack {
                Text(header)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                // Section total
                let total = items.reduce(0.0) { $0 + $1.signedAmount }
                Text((total >= 0 ? "+" : "") + settings.formatAmount(abs(total)))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(total >= 0 ? .green : .red)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No transactions found")
                .font(.headline)
                .foregroundColor(.secondary)
            if !searchText.isEmpty || filterType != .all || filterCat != nil {
                Button("Clear Filters") {
                    searchText  = ""
                    filterType  = .all
                    filterCat   = nil
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            Spacer(minLength: 60)
        }
    }
}

// MARK: - Compact Row

struct TxRowCompact: View {
    let transaction: Transaction
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(transaction.category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text(transaction.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text((transaction.type == .income ? "+" : "-") + settings.formatAmount(transaction.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
