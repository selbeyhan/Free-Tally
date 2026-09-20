import Foundation
import Observation

/// Owns the list of counters and all local persistence. Everything is stored as a single
/// JSON file inside the app's sandboxed Documents directory — there is no network code
/// anywhere in this type, and nothing here ever leaves the device.
@Observable
final class CounterStore {
    private(set) var counters: [Counter] = []

    private let fileURL: URL
    private var pendingSaveWorkItem: DispatchWorkItem?
    private var historyStack: [HistoryEntry] = []
    private let maxHistory = 200

    private struct HistoryEntry {
        let counterID: UUID
        let previousValue: Int
    }

    /// `fileURL` is overridable so unit tests can point at a throwaway file instead of
    /// the real Documents directory.
    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("counters.json")
        }
        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Counter].self, from: data) {
            counters = decoded
        }
    }

    private func scheduleSave() {
        pendingSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.persist() }
        pendingSaveWorkItem = workItem
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    /// Writes immediately and cancels any pending debounced save. Call this when the app
    /// is about to background so a rapid burst of taps is never lost.
    func flush() {
        pendingSaveWorkItem?.cancel()
        pendingSaveWorkItem = nil
        persist()
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(counters) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Mutations

    func addCounter(_ counter: Counter) {
        counters.append(counter)
        scheduleSave()
    }

    func updateCounter(_ counter: Counter) {
        guard let index = counters.firstIndex(where: { $0.id == counter.id }) else { return }
        var updated = counter
        updated.updatedAt = .now
        counters[index] = updated
        scheduleSave()
    }

    func deleteCounter(id: UUID) {
        counters.removeAll { $0.id == id }
        historyStack.removeAll { $0.counterID == id }
        scheduleSave()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        counters.move(fromOffsets: source, toOffset: destination)
        scheduleSave()
    }

    @discardableResult
    func increment(id: UUID) -> Int? {
        adjust(id: id) { $0.count += $0.step }
    }

    @discardableResult
    func decrement(id: UUID) -> Int? {
        adjust(id: id) { $0.count -= $0.step }
    }

    func reset(id: UUID) {
        adjust(id: id) { $0.count = 0 }
    }

    @discardableResult
    func setCount(id: UUID, to value: Int) -> Int? {
        adjust(id: id) { $0.count = value }
    }

    @discardableResult
    private func adjust(id: UUID, _ transform: (inout Counter) -> Void) -> Int? {
        guard let index = counters.firstIndex(where: { $0.id == id }) else { return nil }
        let previous = counters[index].count
        transform(&counters[index])
        counters[index].updatedAt = .now
        historyStack.append(HistoryEntry(counterID: id, previousValue: previous))
        if historyStack.count > maxHistory { historyStack.removeFirst() }
        scheduleSave()
        return counters[index].count
    }

    func canUndo(for id: UUID) -> Bool {
        historyStack.contains { $0.counterID == id }
    }

    func undo(id: UUID) {
        guard let lastIndex = historyStack.lastIndex(where: { $0.counterID == id }) else { return }
        let entry = historyStack.remove(at: lastIndex)
        guard let index = counters.firstIndex(where: { $0.id == id }) else { return }
        counters[index].count = entry.previousValue
        counters[index].updatedAt = .now
        scheduleSave()
    }

    func eraseAllData() {
        counters.removeAll()
        historyStack.removeAll()
        scheduleSave()
    }
}
