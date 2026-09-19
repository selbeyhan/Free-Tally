import SwiftUI

/// Used both to create a new counter (`counter == nil`) and to edit an existing one.
struct EditCounterView: View {
    @Environment(CounterStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let counter: Counter?

    @State private var name: String
    @State private var step: Int
    @State private var startingCount: Int
    @State private var colorHex: String
    @State private var symbolName: String
    @State private var showingDeleteConfirmation = false

    init(counter: Counter?) {
        self.counter = counter
        _name = State(initialValue: counter?.name ?? "")
        _step = State(initialValue: counter?.step ?? 1)
        _startingCount = State(initialValue: counter?.count ?? 0)
        _colorHex = State(initialValue: counter?.colorHex ?? Counter.palette[0])
        _symbolName = State(initialValue: counter?.symbolName ?? Counter.symbolChoices[0])
    }

    private var isEditing: Bool { counter != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Push-ups", text: $name)
                }

                Section("Step Size") {
                    Stepper("Count by \(step)", value: $step, in: 1...1000)
                }

                if !isEditing {
                    Section("Starting Count") {
                        Stepper("\(startingCount)", value: $startingCount, in: -1_000_000...1_000_000)
                    }
                }

                Section("Color") {
                    colorGrid
                }

                Section("Icon") {
                    symbolGrid
                }

                if isEditing {
                    Section {
                        Button("Delete Counter", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Counter" : "New Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete this counter? This can't be undone.", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let counter {
                        store.deleteCounter(id: counter.id)
                    }
                    dismiss()
                }
            }
        }
    }

    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(Counter.palette, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 32, height: 32)
                    .overlay {
                        if hex == colorHex {
                            Circle().stroke(.primary, lineWidth: 2).padding(-3)
                        }
                    }
                    .onTapGesture { colorHex = hex }
                    .accessibilityLabel("Color swatch")
                    .accessibilityAddTraits(hex == colorHex ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private var symbolGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
            ForEach(Counter.symbolChoices, id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(
                        symbol == symbolName ? Color(hex: colorHex).opacity(0.25) : Color.clear,
                        in: Circle()
                    )
                    .onTapGesture { symbolName = symbol }
                    .accessibilityLabel("Icon")
                    .accessibilityAddTraits(symbol == symbolName ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if var counter {
            counter.name = trimmed
            counter.step = max(1, step)
            counter.colorHex = colorHex
            counter.symbolName = symbolName
            store.updateCounter(counter)
        } else {
            let newCounter = Counter(
                name: trimmed,
                count: startingCount,
                step: max(1, step),
                colorHex: colorHex,
                symbolName: symbolName
            )
            store.addCounter(newCounter)
        }
        dismiss()
    }
}

#Preview {
    EditCounterView(counter: nil)
        .environment(CounterStore())
}
