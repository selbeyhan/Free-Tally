import SwiftUI

/// A single tally counter. Everything about a counter lives in this value type,
/// which is what gets persisted to disk as JSON — no server-side representation exists.
struct Counter: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var count: Int
    var step: Int
    var colorHex: String
    var symbolName: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        count: Int = 0,
        step: Int = 1,
        colorHex: String = Counter.palette[0],
        symbolName: String = Counter.symbolChoices[0],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.count = count
        self.step = max(1, step)
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var color: Color { Color(hex: colorHex) }

    static let palette: [String] = [
        "FF3B30", "FF9500", "FFCC00", "34C759", "00C7BE",
        "30B0C7", "32ADE6", "007AFF", "5856D6", "AF52DE", "FF2D55", "8E8E93"
    ]

    static let symbolChoices: [String] = [
        "number.circle.fill", "flame.fill", "drop.fill", "cup.and.saucer.fill",
        "figure.walk", "book.fill", "pawprint.fill", "leaf.fill",
        "dumbbell.fill", "bolt.fill", "star.fill", "heart.fill",
        "gamecontroller.fill", "fork.knife", "moon.stars.fill", "sun.max.fill",
        "cart.fill", "bell.fill", "pencil", "checkmark.circle.fill"
    ]
}
