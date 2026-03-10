import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    @EnvironmentObject var store: TransactionStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: transaction.category.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(transaction.type.color)
                .frame(width: 42, height: 42)
                .background(transaction.type.color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.category.rawValue)
                    .font(.subheadline.weight(.semibold))

                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text((transaction.type == .income ? "+" : "−") + settings.formatAmount(transaction.amount))
                .font(.subheadline.bold())
                .foregroundColor(transaction.type.color)
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
