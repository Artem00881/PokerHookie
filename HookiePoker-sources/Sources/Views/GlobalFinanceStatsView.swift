
import SwiftUI
import SwiftData

struct GlobalFinanceStatsView: View {
    @Query private var sessions: [Session]
    init() { _sessions = Query(sort: [SortDescriptor(\Session.date, order: .reverse)]) }
    var body: some View {
        List {
            let buyIns = sessions.map { $0.totalBuyIns }.reduce(0, +)
            let cashOuts = sessions.map { $0.totalCashOuts }.reduce(0, +)
            let expenses = sessions.map { $0.totalExpenses }.reduce(0, +)
            let delta = buyIns - cashOuts - expenses

            Section("Итого за всё время") {
                HStack { Text("Бай-ины"); Spacer(); Text(buyIns.formattedUAH) }
                HStack { Text("Выводы"); Spacer(); Text(cashOuts.formattedUAH) }
                HStack { Text("Расходы"); Spacer(); Text(expenses.formattedUAH) }
                HStack { Text("Дебит–кредит"); Spacer();
                        Text(delta == 0 ? "Сошлось" : (delta > 0 ? "+\(delta.formattedUAH)" : delta.formattedUAH))
                        .foregroundStyle(delta == 0 ? .secondary : .orange) }
            }
        }.navigationTitle("Финансы")
    }
}
