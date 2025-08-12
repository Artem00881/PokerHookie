
import Foundation
import SwiftData

@Model
final class Player {
    @Attribute(.unique) var name: String
    init(name: String) { self.name = name }
}

@Model
final class BuyIn {
    var amount: Int
    var date: Date
    init(amount: Int, date: Date = .now) { self.amount = amount; self.date = date }
}

@Model
final class Participation {
    var player: Player
    var buyIns: [BuyIn] = []
    var cashOut: Int? = nil
    var createdAt: Date = .now

    init(player: Player) { self.player = player }

    var totalBuyIns: Int { buyIns.map { $0.amount }.reduce(0, +) }
    var profit: Int { (cashOut ?? 0) - totalBuyIns }
}

@Model
final class Session {
    var date: Date
    var isClosed: Bool = false
    var participations: [Participation] = []
    var rake: Int = 0
    var dealerSalary: Int = 0
    var dealerTips: Int = 0

    init(date: Date, isClosed: Bool = false) {
        self.date = date
        self.isClosed = isClosed
    }

    var totalBuyIns: Int { participations.map { $0.totalBuyIns }.reduce(0, +) }
    var totalCashOuts: Int { participations.map { $0.cashOut ?? 0 }.reduce(0, +) }
    var totalExpenses: Int { rake + dealerSalary + dealerTips }
    var balanceDelta: Int { totalBuyIns - totalCashOuts - totalExpenses }
}

// helpers
extension Int {
    var formattedUAH: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "UAH"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: self)) ?? "₴\(self)"
    }
}

enum CurrencyPreset: Int, CaseIterable, Identifiable {
    case _200 = 200, _500 = 500, _1000 = 1000, _2000 = 2000
    var id: Int { rawValue }
    var title: String { "₴\(rawValue)" }
}
