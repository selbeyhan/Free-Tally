import SwiftUI

/// Used both to create a new counter (`counter == nil`) and to edit an existing one.
struct EditCounterView: View {
    @Environment(CounterStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let counter: Counter?

    @State private var name: String
    @State private var step: Int
    @State private var count: Int
    @State private var colorHex: String
    @State private var symbolName: String
    @State private var iconKind: IconKind
    @State private var isCustomEmojiExpanded = false
    @State private var customEmojiText = ""
    @State private var showingDeleteConfirmation = false

    init(counter: Counter?) {
        self.counter = counter
        _name = State(initialValue: counter?.name ?? "")
        _step = State(initialValue: counter?.step ?? 1)
        _count = State(initialValue: counter?.count ?? 0)
        _colorHex = State(initialValue: counter?.colorHex ?? Counter.palette[0])
        _symbolName = State(initialValue: counter?.symbolName ?? Counter.symbolChoices[0])
        _iconKind = State(initialValue: counter?.iconKind ?? .symbol)

        // If editing a counter whose emoji predates the curated grid (a free-typed
        // emoji not in Counter.emojiChoices), open with "Other…" already expanded and
        // pre-filled, rather than looking like nothing is selected.
        let existingEmoji = (counter?.iconKind == .emoji) ? counter?.symbolName : nil
        let isCustomEmoji = existingEmoji.map { !Counter.emojiChoices.contains($0) } ?? false
        _customEmojiText = State(initialValue: isCustomEmoji ? (existingEmoji ?? "") : "")
        _isCustomEmojiExpanded = State(initialValue: isCustomEmoji)
    }

    private var isEditing: Bool { counter != nil }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if iconKind == .emoji, symbolName.isEmpty { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Push-ups", text: $name)
                }

                Section("Step Size") {
                    NumericInputField(title: "Step Size", value: $step, range: Counter.stepRange)
                }

                Section("Count") {
                    NumericInputField(title: "Count", value: $count, range: Counter.countRange, allowsNegative: true)
                }

                Section {
                    Picker("Icon Type", selection: $iconKind) {
                        Text("Symbol").tag(IconKind.symbol)
                        Text("Emoji").tag(IconKind.emoji)
                    }
                    .pickerStyle(.segmented)

                    switch iconKind {
                    case .symbol:
                        symbolGrid
                    case .emoji:
                        emojiPicker
                    }
                } header: {
                    Text("Icon")
                } footer: {
                    if iconKind == .emoji {
                        Text("Choose an emoji above, or tap “Other…” to type your own.")
                    }
                }

                Section("Color") {
                    colorGrid
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
                        .disabled(!canSave)
                }
            }
            .onChange(of: iconKind) { _, newValue in
                guard newValue == .emoji else { return }
                guard !Counter.emojiChoices.contains(symbolName), customEmojiText.isEmpty else { return }
                symbolName = Counter.emojiChoices[0]
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

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            emojiGrid

            DisclosureGroup(isExpanded: $isCustomEmojiExpanded) {
                HStack {
                    Text("Custom")
                        .foregroundStyle(.secondary)
                    Spacer()
                    EmojiTextField(text: $customEmojiText, placeholder: "🔥")
                        .frame(width: 50)
                        .onChange(of: customEmojiText) { _, newValue in
                            // EmojiTextField already guarantees this is always either
                            // empty or exactly one valid emoji, so no clamping needed
                            // here. Don't clear symbolName when the field is emptied
                            // mid-retype — the prior selection (grid tap or earlier
                            // custom entry) should stay in effect until a new emoji
                            // actually lands.
                            guard !newValue.isEmpty else { return }
                            symbolName = newValue
                        }
                }
                .padding(.vertical, 2)
            } label: {
                Text("Other…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emojiGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
            ForEach(Counter.emojiChoices, id: \.self) { emoji in
                Text(emoji)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(
                        emoji == symbolName ? Color(hex: colorHex).opacity(0.25) : Color.clear,
                        in: Circle()
                    )
                    .onTapGesture { symbolName = emoji }
                    .accessibilityLabel("Icon")
                    .accessibilityAddTraits(emoji == symbolName ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if var counter {
            counter.name = trimmed
            counter.step = max(1, step)
            counter.count = count
            counter.colorHex = colorHex
            counter.symbolName = symbolName
            counter.iconKind = iconKind
            store.updateCounter(counter)
        } else {
            let newCounter = Counter(
                name: trimmed,
                count: count,
                step: max(1, step),
                colorHex: colorHex,
                symbolName: symbolName,
                iconKind: iconKind
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
