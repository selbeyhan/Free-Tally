import SwiftUI

/// A single tally counter. Everything about a counter lives in this value type,
/// which is what gets persisted to disk as JSON — no server-side representation exists.
struct Counter: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var count: Int
    var step: Int
    var colorHex: String
    /// An SF Symbol name or a literal emoji character, depending on `iconKind`.
    var symbolName: String
    var iconKind: IconKind
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        count: Int = 0,
        step: Int = 1,
        colorHex: String = Counter.palette[0],
        symbolName: String = Counter.symbolChoices[0],
        iconKind: IconKind = .symbol,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.count = count
        self.step = max(1, step)
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.iconKind = iconKind
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

    static let emojiChoices: [String] = [
        "🔢", "🔥", "💧", "☕", "🏃", "📚", "🐾", "🌿",
        "💪", "⚡", "⭐", "❤️", "🎮", "🍽️", "🌙", "☀️",
        "🛒", "🔔", "✏️", "✅"
    ]

    static let countRange: ClosedRange<Int> = -1_000_000...1_000_000
    static let stepRange: ClosedRange<Int> = 1...1000

    private enum CodingKeys: String, CodingKey {
        case id, name, count, step, colorHex, symbolName, iconKind, createdAt, updatedAt
    }

    /// Custom decode so counters saved before `iconKind` existed still load. Swift's
    /// synthesized `Decodable` throws on a missing key rather than falling back to a
    /// default, and since the whole array decode is wrapped in `try?` in
    /// `CounterStore.load()`, one throwing element would silently drop every saved
    /// counter — not just default this one field.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        count = try container.decode(Int.self, forKey: .count)
        step = try container.decode(Int.self, forKey: .step)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        symbolName = try container.decode(String.self, forKey: .symbolName)
        iconKind = try container.decodeIfPresent(IconKind.self, forKey: .iconKind) ?? .symbol
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

enum IconKind: String, Codable, CaseIterable, Hashable {
    case symbol
    case emoji
}
