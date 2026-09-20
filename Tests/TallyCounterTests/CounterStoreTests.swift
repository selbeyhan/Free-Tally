import XCTest
@testable import TallyCounter

final class CounterStoreTests: XCTestCase {
    private var tempURL: URL!
    private var store: CounterStore!

    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        store = CounterStore(fileURL: tempURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempURL)
        store = nil
        tempURL = nil
        super.tearDown()
    }

    func testAddCounterAppendsToList() {
        let counter = Counter(name: "Push-ups")
        store.addCounter(counter)

        XCTAssertEqual(store.counters.count, 1)
        XCTAssertEqual(store.counters.first?.name, "Push-ups")
    }

    func testIncrementUsesStepSize() {
        let counter = Counter(name: "Reps", step: 5)
        store.addCounter(counter)

        store.increment(id: counter.id)

        XCTAssertEqual(store.counters.first?.count, 5)
    }

    func testDecrementUsesStepSize() {
        let counter = Counter(name: "Reps", count: 10, step: 3)
        store.addCounter(counter)

        store.decrement(id: counter.id)

        XCTAssertEqual(store.counters.first?.count, 7)
    }

    func testStepSizeIsClampedToAtLeastOne() {
        let counter = Counter(name: "Reps", step: 0)
        XCTAssertEqual(counter.step, 1)
    }

    func testResetSetsCountToZero() {
        let counter = Counter(name: "Reps", count: 42)
        store.addCounter(counter)

        store.reset(id: counter.id)

        XCTAssertEqual(store.counters.first?.count, 0)
    }

    func testUndoRestoresPreviousValue() {
        let counter = Counter(name: "Reps")
        store.addCounter(counter)

        store.increment(id: counter.id)
        store.increment(id: counter.id)
        XCTAssertEqual(store.counters.first?.count, 2)

        store.undo(id: counter.id)
        XCTAssertEqual(store.counters.first?.count, 1)
    }

    func testCanUndoReflectsHistoryPerCounter() {
        let counter = Counter(name: "Reps")
        store.addCounter(counter)

        XCTAssertFalse(store.canUndo(for: counter.id))
        store.increment(id: counter.id)
        XCTAssertTrue(store.canUndo(for: counter.id))
    }

    func testDeleteCounterRemovesIt() {
        let counter = Counter(name: "Reps")
        store.addCounter(counter)

        store.deleteCounter(id: counter.id)

        XCTAssertTrue(store.counters.isEmpty)
    }

    func testEraseAllDataClearsEverything() {
        store.addCounter(Counter(name: "A"))
        store.addCounter(Counter(name: "B"))

        store.eraseAllData()

        XCTAssertTrue(store.counters.isEmpty)
    }

    func testPersistenceRoundTrip() {
        let counter = Counter(name: "Reps", count: 3)
        store.addCounter(counter)
        store.flush()

        let reloaded = CounterStore(fileURL: tempURL)

        XCTAssertEqual(reloaded.counters.first?.name, "Reps")
        XCTAssertEqual(reloaded.counters.first?.count, 3)
    }

    func testSetCountSetsExactValue() {
        let counter = Counter(name: "Reps", count: 5)
        store.addCounter(counter)

        store.setCount(id: counter.id, to: 42)

        XCTAssertEqual(store.counters.first?.count, 42)
    }

    func testSetCountAllowsNegativeValues() {
        let counter = Counter(name: "Reps", count: 5)
        store.addCounter(counter)

        store.setCount(id: counter.id, to: -10)

        XCTAssertEqual(store.counters.first?.count, -10)
    }

    func testSetCountIsUndoable() {
        let counter = Counter(name: "Reps", count: 5)
        store.addCounter(counter)

        store.setCount(id: counter.id, to: 100)
        XCTAssertTrue(store.canUndo(for: counter.id))

        store.undo(id: counter.id)
        XCTAssertEqual(store.counters.first?.count, 5)
    }

    func testSetCountReturnsNilForUnknownID() {
        XCTAssertNil(store.setCount(id: UUID(), to: 10))
    }

    func testLoadingOldPersistedJSONWithoutIconKindDoesNotDropCounters() throws {
        let oldShapeJSON = """
        [{"id":"\(UUID().uuidString)","name":"Push-ups","count":7,"step":1,
          "colorHex":"FF3B30","symbolName":"flame.fill",
          "createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """.data(using: .utf8)!
        try oldShapeJSON.write(to: tempURL)

        let reloaded = CounterStore(fileURL: tempURL)

        XCTAssertEqual(reloaded.counters.count, 1)
        XCTAssertEqual(reloaded.counters.first?.symbolName, "flame.fill")
        XCTAssertEqual(reloaded.counters.first?.iconKind, .symbol)
    }
}

final class CounterCodableTests: XCTestCase {
    func testDecodingOldJSONWithoutIconKindDefaultsToSymbol() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Push-ups","count":3,"step":1,
         "colorHex":"FF3B30","symbolName":"flame.fill",
         "createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let counter = try decoder.decode(Counter.self, from: json)

        XCTAssertEqual(counter.iconKind, .symbol)
    }

    func testDecodingNewJSONWithEmojiIconKind() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Coffee","count":0,"step":1,
         "colorHex":"FF9500","symbolName":"☕️","iconKind":"emoji",
         "createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let counter = try decoder.decode(Counter.self, from: json)

        XCTAssertEqual(counter.iconKind, .emoji)
        XCTAssertEqual(counter.symbolName, "☕️")
    }
}
