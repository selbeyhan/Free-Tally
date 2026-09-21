import SwiftUI

struct CounterDetailView: View {
    let counterID: UUID

    @Environment(CounterStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @State private var volumeHandler = VolumeButtonHandler()
    @State private var showingEditSheet = false
    @State private var showingResetConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingQuickEditAlert = false
    @State private var quickEditText = ""

    private var counter: Counter? {
        store.counters.first { $0.id == counterID }
    }

    var body: some View {
        Group {
            if let counter {
                counterContent(counter)
            } else {
                ContentUnavailableView("Counter Deleted", systemImage: "trash")
            }
        }
        .navigationTitle(counter?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingEditSheet) {
            EditCounterView(counter: counter)
        }
        .confirmationDialog("Reset counter to 0?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                store.reset(id: counterID)
            }
        }
        .confirmationDialog("Delete this counter? This can't be undone.", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deleteCounter(id: counterID)
                dismiss()
            }
        }
        .alert("Set Count", isPresented: $showingQuickEditAlert) {
            TextField("Count", text: $quickEditText)
                .keyboardType(.numbersAndPunctuation)
            Button("Cancel", role: .cancel) {}
            Button("Set") {
                let trimmed = quickEditText.trimmingCharacters(in: .whitespaces)
                if let value = Int(trimmed) {
                    let clamped = min(max(value, Counter.countRange.lowerBound), Counter.countRange.upperBound)
                    store.setCount(id: counterID, to: clamped)
                    fireFeedback()
                }
            }
            .disabled(Int(quickEditText.trimmingCharacters(in: .whitespaces)) == nil)
        } message: {
            Text("Enter a new value for this counter.")
        }
        .onAppear { syncVolumeHandler() }
        .onDisappear {
            volumeHandler.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) { syncVolumeHandler() }
        .onChange(of: settings.useVolumeButtons) { syncVolumeHandler() }
        .onChange(of: settings.keepScreenAwake) { syncIdleTimer() }
    }

    @ViewBuilder
    private func counterContent(_ counter: Counter) -> some View {
        VStack(spacing: 28) {
            Spacer()

            Text("\(counter.count)")
                .font(.system(size: 88, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(counter.color)
                .contentTransition(.numericText(value: Double(counter.count)))
                .animation(.snappy, value: counter.count)
                .accessibilityLabel("Count")
                .accessibilityValue("\(counter.count)")
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            quickEditText = "\(counter.count)"
                            showingQuickEditAlert = true
                        }
                        .exclusively(before:
                            TapGesture()
                                .onEnded {
                                    store.increment(id: counterID)
                                    fireFeedback()
                                }
                        )
                )

            Text(settings.useVolumeButtons ? "Tap anywhere, or press a volume button" : "Tap anywhere to count")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 24) {
                controlButton(systemImage: "arrow.uturn.backward") {
                    store.undo(id: counterID)
                    fireFeedback()
                }
                .disabled(!store.canUndo(for: counterID))
                .opacity(store.canUndo(for: counterID) ? 1 : 0.35)

                controlButton(systemImage: "minus") {
                    store.decrement(id: counterID)
                    fireFeedback()
                }
            }
            .padding(.bottom, 16)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            store.increment(id: counterID)
            fireFeedback()
        }
    }

    private func controlButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
                .background(.thinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit Counter", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("Reset to 0", systemImage: "arrow.counterclockwise")
                }
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Counter", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Counter Options")
        }
    }

    private func syncVolumeHandler() {
        guard settings.useVolumeButtons, scenePhase == .active, counter != nil else {
            volumeHandler.stop()
            syncIdleTimer()
            return
        }
        volumeHandler.onVolumeButtonPressed = {
            store.increment(id: counterID)
            fireFeedback()
        }
        volumeHandler.start()
        syncIdleTimer()
    }

    private func syncIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = settings.keepScreenAwake && scenePhase == .active
    }

    private func fireFeedback() {
        FeedbackManager.vibrate(enabled: settings.hapticsEnabled, length: settings.hapticLength)
        FeedbackManager.playSound(enabled: settings.soundEnabled, length: settings.soundLength)
    }
}

#Preview {
    let store = CounterStore()
    let counter = Counter(name: "Push-ups", count: 12, colorHex: "FF3B30", symbolName: "flame.fill")
    store.addCounter(counter)
    return NavigationStack {
        CounterDetailView(counterID: counter.id)
    }
    .environment(store)
    .environment(AppSettings())
}
