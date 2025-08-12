
import SwiftUI
import SwiftData

@main
struct PokerHApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(for: [Player.self, BuyIn.self, Participation.self, Session.self])
        }
    }
}
