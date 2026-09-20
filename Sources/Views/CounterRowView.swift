import SwiftUI

struct CounterRowView: View {
    let counter: Counter

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(counter.color.opacity(0.18))
                iconView
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(counter.name)
                    .font(.headline)
                Text(counter.step == 1 ? "Step 1" : "Step \(counter.step)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(counter.count)")
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(counter.color)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var iconView: some View {
        switch counter.iconKind {
        case .symbol:
            Image(systemName: counter.symbolName)
                .foregroundStyle(counter.color)
                .font(.system(size: 18, weight: .semibold))
        case .emoji:
            Text(counter.symbolName)
                .font(.system(size: 20))
        }
    }
}

#Preview {
    List {
        CounterRowView(counter: Counter(name: "Push-ups", count: 42, step: 1, colorHex: "FF3B30", symbolName: "flame.fill"))
        CounterRowView(counter: Counter(name: "Glasses of Water", count: 5, step: 1, colorHex: "32ADE6", symbolName: "drop.fill"))
    }
}
