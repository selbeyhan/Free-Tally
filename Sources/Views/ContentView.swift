import SwiftUI

struct ContentView: View {
    @Environment(CounterStore.self) private var store
    @State private var showingAddSheet = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if store.counters.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Tally")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !store.counters.isEmpty {
                        EditButton()
                    }
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Counter")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                EditCounterView(counter: nil)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var list: some View {
        List {
            ForEach(store.counters) { counter in
                NavigationLink(value: counter.id) {
                    CounterRowView(counter: counter)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    store.deleteCounter(id: store.counters[index].id)
                }
            }
            .onMove(perform: store.move)
        }
        .navigationDestination(for: UUID.self) { id in
            CounterDetailView(counterID: id)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Counters Yet", systemImage: "number.circle")
        } description: {
            Text("Tap + to create your first tally counter.")
        } actions: {
            Button("Add Counter") { showingAddSheet = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ContentView()
        .environment(CounterStore())
        .environment(AppSettings())
}
