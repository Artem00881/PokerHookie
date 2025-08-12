
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CurrentSessionView()
                .tabItem { Label("Сессия", systemImage: "lock.open.display") }
            SessionHistoryView()
                .tabItem { Label("История", systemImage: "clock.arrow.circlepath") }
            GlobalFinanceStatsView()
                .tabItem { Label("Финансы", systemImage: "chart.bar.xaxis") }
        }
    }
}
