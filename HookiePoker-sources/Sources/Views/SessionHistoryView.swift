
import SwiftUI
import SwiftData

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)]) private var sessions: [Session]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { s in
                    NavigationLink {
                        SessionDetailView(session: s)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(s.date.formatted(date: .abbreviated, time: .omitted)).fontWeight(.semibold)
                                Text(s.isClosed ? "Закрыта" : "Открыта").font(.caption)
                                    .foregroundStyle(s.isClosed ? .secondary : .orange)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Бай-ины: \(s.totalBuyIns.formattedUAH)").foregroundStyle(.secondary)
                                Text("Выводы: \(s.totalCashOuts.formattedUAH)").foregroundStyle(.secondary)
                            }.font(.footnote)
                        }
                    }
                }
                .onDelete { idx in for i in idx { ctx.delete(sessions[i]) }; try? ctx.save() }
            }
            .navigationTitle("История")
        }
    }
}

struct SessionDetailView: View {
    @Bindable var session: Session
    var body: some View {
        List {
            Section("Сводка") {
                HStack { Text("Бай-ины"); Spacer(); Text(session.totalBuyIns.formattedUAH) }
                HStack { Text("Выводы"); Spacer(); Text(session.totalCashOuts.formattedUAH) }
                HStack { Text("Расходы"); Spacer(); Text(session.totalExpenses.formattedUAH) }
                let d = session.balanceDelta
                HStack { Text("Дебит–кредит"); Spacer();
                        Text(d == 0 ? "Сошлось" : (d > 0 ? "+\(d.formattedUAH)" : d.formattedUAH))
                        .foregroundStyle(d == 0 ? .secondary : .orange) }
            }
            Section("Игроки") {
                ForEach(session.participations) { p in
                    HStack {
                        Text(p.player.name)
                        Spacer()
                        let res = (p.cashOut ?? 0) - p.totalBuyIns
                        Text(res.formattedUAH).foregroundStyle(res >= 0 ? .green : .red)
                    }
                }
            }
        }.navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
    }
}
