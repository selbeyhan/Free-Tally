import SwiftUI
import UIKit

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
                    Toggle("Haptic Feedback", isOn: $settings.hapticsEnabled)
                    Toggle("Keep Screen Awake", isOn: $settings.keepScreenAwake)
                } footer: {
                    Text("When enabled, pressing either volume button on a counter's screen adds to it instead of changing the volume. The volume level itself is never actually changed.")
                }

                Section {
                    Button("Test Haptic Feedback") {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
                } footer: {
                    Text("This button has nothing to do with counters, volume buttons, or the audio session — it's a bare UIKit haptic call, for isolating whether haptics work on this device/build at all.")
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
