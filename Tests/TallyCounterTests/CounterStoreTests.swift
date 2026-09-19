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
}
