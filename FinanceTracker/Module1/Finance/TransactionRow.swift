import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(transaction.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text(transaction.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text((transaction.type == .income ? "+" : "−") + settings.formatAmount(transaction.amount))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.type.color)
                Text(transaction.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.delete(transaction)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
