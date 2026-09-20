import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(CounterStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetConfirmation = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section {
                    Toggle("Count with Volume Buttons", isOn: $settings.useVolumeButtons)
                } footer: {
                    Text("When enabled, pressing either volume button on a counter's screen adds to it instead of changing the volume. The volume level itself is never actually changed.")
                }

                Section {
                    Toggle("Haptic Feedback", isOn: $settings.hapticsEnabled)
                    if settings.hapticsEnabled {
                        Picker("Vibration Length", selection: $settings.hapticLength) {
                            ForEach(FeedbackLength.allCases) { length in
                                Text(length.displayName).tag(length)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section {
                    Toggle("Sound Feedback", isOn: $settings.soundEnabled)
                    if settings.soundEnabled {
                        Picker("Sound Length", selection: $settings.soundLength) {
                            ForEach(FeedbackLength.allCases) { length in
                                Text(length.displayName).tag(length)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } footer: {
                    Text("Sound feedback plays through the ringer volume and is silenced by the ring/silent switch, like other system sounds.")
                }

                Section {
                    Toggle("Keep Screen Awake", isOn: $settings.keepScreenAwake)
                }

                Section {
                    Button("Erase All Counters", role: .destructive) {
                        showingResetConfirmation = true
                    }
                } footer: {
                    Text("Tally keeps everything only on this device. There's no account, no cloud sync, no analytics, and no data ever leaves your phone.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Erase all counters? This can't be undone.", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button("Erase Everything", role: .destructive) {
                    store.eraseAllData()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
        .environment(CounterStore())
}
