import SwiftUI

@main
struct TallyCounterApp: App {
    @State private var store = CounterStore()
    @State private var settings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(settings)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                store.flush()
            }
        }
    }
}
