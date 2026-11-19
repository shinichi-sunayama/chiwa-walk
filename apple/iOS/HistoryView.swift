import SwiftUI
import WalkCore

/// きろく: a month calendar (walks per day at a glance) and the chosen day's summary and timeline.
struct HistoryView: View {
    @EnvironmentObject var model: AppModel
    @State private var month = Calendar.current.dateInterval(of: .month, for: .now)!.start
    @State private var selected = Calendar.current.startOfDay(for: .now)
    @State private var adding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                let summaries = Walks.summaries(events: model.events, calendar: .current)
                VStack(spacing: 14) {
                    MonthCalendar(month: $month, selected: $selected, summaries: summaries)
                    DaySection(day: selected, summary: summaries[selected])
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("きろく")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { adding = true } label: { Image(systemName: "plus") }
                        .disabled(model.dogs.isEmpty)
                        .accessibilityLabel("あとから きろくを たす")
                }
            }
            .sheet(isPresented: $adding) { EventEditView(original: nil, day: selected) }
        }
    }
}

/// Month grid. A day with walks shows a green paw and how many; a day with only taps shows a dot.
struct MonthCalendar: View {
    @Binding var month: Date
    @Binding var selected: Date
    var summaries: [Date: DaySummary]
    private let cal = Calendar.current

    private var days: [Date?] {
        let count = cal.range(of: .day, in: .month, for: month)!.count
        let lead = (cal.component(.weekday, from: month) - cal.firstWeekday + 7) % 7
        return Array(repeating: nil, count: lead) + (0..<count).map { cal.date(byAdding: .day, value: $0, to: month)! }
    }

    private var weekdays: [String] {
        let s = cal.veryShortWeekdaySymbols
        let k = cal.firstWeekday - 1
        return Array(s[k...] + s[..<k])
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("まえの月")
                Spacer()
                Text(month, format: .dateTime.year().month()).font(Theme.font(17)).foregroundStyle(Theme.text)
                Spacer()
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
                    .disabled(cal.isDate(month, equalTo: .now, toGranularity: .month))
                    .accessibilityLabel("つぎの月")
            }
            .font(.system(size: 17, weight: .bold))
            .tint(Theme.orange)
            .padding(.horizontal, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, w in
                    Text(w).font(Theme.font(11)).foregroundStyle(Theme.muted)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day { cell(day) } else { Color.clear.frame(height: 48) }
                }
            }

            HStack(spacing: 14) {
                HStack(spacing: 3) {
                    Image(systemName: "pawprint.fill").foregroundStyle(Theme.green)
                    Text("おさんぽの回数")
                }
                HStack(spacing: 3) {
                    Circle().fill(Theme.orange.opacity(0.7)).frame(width: 6, height: 6)
                    Text("きろくだけ")
                }
            }
            .font(Theme.font(11)).foregroundStyle(Theme.muted)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
    }

    private func cell(_ day: Date) -> some View {
        let s = summaries[day]
        let isSelected = cal.isDate(day, inSameDayAs: selected)
        let isToday = cal.isDateInToday(day)
        let future = day > .now
        return Button { selected = day } label: {
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: day))")
                    .font(Theme.font(14))
                    .foregroundStyle(isSelected ? .white : (future ? Theme.muted.opacity(0.5) : Theme.text))
                if let s, s.walks > 0 {
                    HStack(spacing: 1) {
                        Image(systemName: "pawprint.fill").font(.system(size: 8))
                        Text("\(s.walks)").font(Theme.font(10))
                    }
                    .foregroundStyle(isSelected ? .white : Theme.green)
                } else if s != nil {
                    Circle().fill(isSelected ? Color.white : Theme.orange.opacity(0.7))
                        .frame(width: 5, height: 5).padding(.vertical, 3)
                } else {
                    Color.clear.frame(height: 11)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Theme.orange : (isToday ? Theme.chip : Color.clear)))
        }
        .buttonStyle(.plain)
        .disabled(future)
        .accessibilityLabel(Text(day, format: .dateTime.month().day()) + Text(s.map { "、" + Walks.walkText($0) } ?? ""))
    }

    private func shift(_ months: Int) {
        if let m = cal.date(byAdding: .month, value: months, to: month) { month = m }
    }
}

/// The chosen day: walks and their total minutes, taps per dog, then the timeline.
struct DaySection: View {
    @EnvironmentObject var model: AppModel
    var day: Date
    var summary: DaySummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day, format: .dateTime.month().day().weekday(.wide))
                .font(Theme.font(17)).foregroundStyle(Theme.text)
            if let summary {
                DaySummaryCard(day: day, summary: summary)
                DayTimeline(day: day)
            } else {
                Text("この日の きろくは ありません").font(Theme.font(14)).foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 「おさんぽ 2回・55分」 and, per dog, 「おしっこ 3・うんち 1」.
struct DaySummaryCard: View {
    @EnvironmentObject var model: AppModel
    var day: Date
    var summary: DaySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(Walks.walkText(summary), systemImage: "figure.walk")
                .font(Theme.font(16)).foregroundStyle(Theme.green)
            ForEach(model.dogs) { dog in
                let parts = EventKind.buttonKinds.compactMap { kind -> String? in
                    let n = WalkLog.count(kind, dog: dog.id, in: model.events, on: day, calendar: .current)
                    return n > 0 ? "\(kind.emoji)\(kind.label) \(n)" : nil
                }
                if !parts.isEmpty {
                    HStack(spacing: 6) {
                        DogFace(dog: dog, size: 22)
                        Text(dog.name).font(Theme.font(13)).foregroundStyle(Theme.text)
                        Text(parts.joined(separator: "・")).font(Theme.font(13)).foregroundStyle(Theme.muted)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
    }
}

/// Fix one record, or add one afterwards (original == nil).
struct EventEditView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let original: WalkEvent?
    /// For adding: the day chosen in the calendar (the time starts at noon on past days).
    var day: Date? = nil
    @State private var date = Date.now
    @State private var kind = EventKind.pee
    @State private var dogIDs: Set<UUID> = []
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("いつ") {
                    DatePicker("にちじ", selection: $date, in: ...Date.now.addingTimeInterval(60))
                }
                Section("なにを") {
                    Picker("きろく", selection: $kind) {
                        ForEach(EventKind.allCases, id: \.self) { k in Text("\(k.emoji) \(k.label)").tag(k) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section(original == nil ? "だれの（いくつでも）" : "だれの") {
                    ForEach(model.dogs) { dog in
                        Button {
                            if original != nil {
                                dogIDs = [dog.id]
                            } else if dogIDs.contains(dog.id) {
                                dogIDs.remove(dog.id)
                            } else {
                                dogIDs.insert(dog.id)
                            }
                        } label: {
                            HStack {
                                DogFace(dog: dog, size: 32)
                                Text(dog.name).foregroundStyle(Theme.text)
                                Spacer()
                                if dogIDs.contains(dog.id) { Image(systemName: "checkmark").foregroundStyle(Theme.orange) }
                            }
                        }
                    }
                }
                if original != nil {
                    Section {
                        Button("この きろくを けす", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .font(Theme.font(16))
            .navigationTitle(original == nil ? "あとから たす" : "きろくを なおす")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("ほぞん") { save() }.disabled(dogIDs.isEmpty)
                }
            }
            .confirmationDialog("この きろくを けしますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("けす", role: .destructive) {
                    if let original { model.remove([original.id]) }
                    dismiss()
                }
            }
            .onAppear {
                if let original {
                    date = original.date
                    kind = original.kind
                    dogIDs = [original.dogID]
                } else {
                    if let day, !Calendar.current.isDateInToday(day) {
                        date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
                    }
                    dogIDs = model.selectedDogIDs.isEmpty ? Set(model.dogs.prefix(1).map(\.id)) : model.selectedDogIDs
                }
            }
        }
    }

    private func save() {
        if var e = original, let dog = dogIDs.first {
            e.date = date
            e.kind = kind
            e.dogID = dog
            model.update(e)
        } else {
            let ids = model.dogs.map(\.id).filter { dogIDs.contains($0) }
            model.add(WalkLog.makeEvents(kind: kind, dogIDs: ids, date: date, author: model.authorName))
        }
        dismiss()
    }
}
