
import SwiftUI
import SwiftData

private struct InfoRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack { Text(title); Spacer(); Text(value).foregroundStyle(.secondary) }
    }
}

struct CurrentSessionView: View {
    @Environment(\.modelContext) private var ctx

    @Query(
        filter: #Predicate<Session> { $0.isClosed == false },
        sort: [SortDescriptor(\Session.date, order: .reverse)],
        animation: .default
    ) private var openSessions: [Session]

    var body: some View {
        NavigationStack {
            Group {
                if let session = openSessions.first {
                    SessionEditorView(session: session)
                } else {
                    NewSessionView()
                }
            }
            .navigationTitle("Текущая сессия")
        }
    }
}

struct NewSessionView: View {
    @Environment(\.modelContext) private var ctx
    @State private var date = Date()

    var body: some View {
        Form {
            DatePicker("Дата", selection: $date, displayedComponents: .date)
            Section {
                Button {
                    let s = Session(date: date, isClosed: false)
                    ctx.insert(s)
                    try? ctx.save()
                } label: { Label("Создать сессию", systemImage: "plus.circle.fill") }
            }
        }.navigationTitle("Новая сессия")
    }
}

struct SessionEditorView: View {
    @Environment(\.modelContext) private var ctx
    @Bindable var session: Session
    @State private var showAdd = false
    @State private var showClose = false

    var body: some View {
        List {
            Section {
                ForEach(session.participations) { p in
                    NavigationLink {
                        ParticipationEditorView(part: p)
                    } label: {
                        HStack {
                            Text(p.player.name)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Бай-ины: \(p.totalBuyIns.formattedUAH)").font(.subheadline).foregroundStyle(.secondary)
                                Text("Вывод: \((p.cashOut ?? 0).formattedUAH)").font(.subheadline).foregroundStyle(.secondary)
                                let pr = p.profit
                                Text(pr >= 0 ? "+\(pr.formattedUAH)" : p.formattedUAH).fontWeight(.semibold)
                                    .foregroundStyle(pr >= 0 ? .green : .red)
                            }
                        }
                    }
                }.onDelete { idx in for i in idx { ctx.delete(session.participations[i]) }; try? ctx.save() }
            } header: {
                HStack { Text("Игроки"); Spacer(); Button { showAdd = true } label: { Image(systemName: "plus.circle.fill") } }
            }

            Section("Расходы") {
                MoneyField(title: "Рейк", value: $session.rake)
                MoneyField(title: "ЗП дилеров", value: $session.dealerSalary)
                MoneyField(title: "Чай дилеров", value: $session.dealerTips)
            }

            Section("Итоги") {
                InfoRow(title: "Все бай-ины", value: session.totalBuyIns.formattedUAH)
                InfoRow(title: "Все выводы", value: session.totalCashOuts.formattedUAH)
                InfoRow(title: "Расходы", value: session.totalExpenses.formattedUAH)
                let d = session.balanceDelta
                InfoRow(title: "Дебит–кредит", value: d == 0 ? "Сошлось" : (d > 0 ? "+\(d.formattedUAH)" : d.formattedUAH))
                    .foregroundStyle(d == 0 ? Color.secondary : Color.orange)
            }

            if !session.isClosed {
                Section { Button(role: .destructive) { showClose = true } label: { Label("Закрыть сессию", systemImage: "lock.fill") } }
            }
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
        .sheet(isPresented: $showAdd) { AddPlayerSheet(session: session) }
        .alert("Закрыть сессию?", isPresented: $showClose) {
            Button("Отмена", role: .cancel) {}
            Button("Закрыть", role: .destructive) { session.isClosed = true; try? ctx.save() }
        } message: { Text("После закрытия смотрите в Истории.") }
    }
}

struct AddPlayerSheet: View {
    @Environment(\.modelContext) private var ctx
    @Bindable var session: Session
    @Query(sort: [SortDescriptor(\Player.name)]) private var players: [Player]
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Существующие") {
                    let present = Set(session.participations.map { $0.player.persistentModelID })
                    ForEach(players.filter { !present.contains($0.persistentModelID) }) { p in
                        Button(p.name) { let part = Participation(player: p); session.participations.append(part); try? ctx.save() }
                    }
                }
                Section("Новый игрок") {
                    TextField("Имя игрока", text: $newName)
                    Button {
                        let p = Player(name: newName.trimmingCharacters(in: .whitespaces))
                        ctx.insert(p)
                        session.participations.append(Participation(player: p))
                        try? ctx.save()
                        newName = ""
                    } label: { Label("Добавить", systemImage: "person.crop.circle.badge.plus") }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Добавить игрока")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Готово") {} } }
        }
    }
}

struct ParticipationEditorView: View {
    @Environment(\.modelContext) private var ctx
    @Bindable var part: Participation
    @State private var custom = 0
    @FocusState private var focus: Bool

    var body: some View {
        Form {
            Section("Бай-ины") {
                HStack {
                    ForEach(CurrencyPreset.allCases) { p in
                        Button(p.title) { part.buyIns.append(BuyIn(amount: p.rawValue)); try? ctx.save() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                MoneyField(title: "Другая сумма", value: $custom).focused($focus)
                Button("Добавить другой бай-ин") {
                    guard custom > 0 else { return }
                    part.buyIns.append(BuyIn(amount: custom)); custom = 0; focus = False
                    try? ctx.save()
                }
            }
            Section("Вывод") {
                MoneyField(title: "Сумма вывода", value: Binding(
                    get: { part.cashOut ?? 0 },
                    set: { part.cashOut = $0 }
                ))
            }
            Section("Итог") {
                HStack { Text("Всего бай-инов"); Spacer(); Text(part.totalBuyIns.formattedUAH) }
                HStack { Text("Вывод"); Spacer(); Text((part.cashOut ?? 0).formattedUAH) }
                let p = part.profit
                HStack { Text("Результат"); Spacer(); Text(p >= 0 ? "+\(p.formattedUAH)" : p.formattedUAH).foregroundStyle(p >= 0 ? .green : .red) }
            }
        }.navigationTitle(part.player.name)
    }
}
