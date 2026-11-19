import SwiftUI
import WalkCore

/// A day's records as rows: a walk is one row 「7:10〜7:42 おさんぽ 32分」, a tap for several dogs is one
/// row with their faces. Tap a row to fix it; long press to delete. Used by きょう and きろく.
struct DayTimeline: View {
    @EnvironmentObject var model: AppModel
    var day: Date
    @State private var editingEvent: WalkEvent?
    @State private var editingWalk: WalkSession?
    @State private var choosing: [WalkEvent]?

    var body: some View {
        let items = Walks.timeline(on: day, events: model.events, calendar: .current)
        VStack(spacing: 6) {
            ForEach(items) { item in
                Button { open(item) } label: { row(item) }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("けす", systemImage: "trash", role: .destructive) { model.remove(item.eventIDs) }
                    }
            }
        }
        .sheet(item: $editingEvent) { e in EventEditView(original: e) }
        .sheet(item: $editingWalk) { w in WalkEditView(walk: w) }
        .confirmationDialog("どの子の きろくを なおす？", isPresented: Binding(
            get: { choosing != nil }, set: { if !$0 { choosing = nil } }
        ), titleVisibility: .visible) {
            ForEach(choosing ?? []) { e in
                Button(model.dog(e.dogID)?.name ?? "") { editingEvent = e }
            }
            Button("まとめて けす", role: .destructive) { model.remove((choosing ?? []).map(\.id)) }
        }
    }

    private func open(_ item: TimelineItem) {
        switch item {
        case .walk(let w): editingWalk = w
        case .tap(let events): if events.count == 1 { editingEvent = events[0] } else { choosing = events }
        }
    }

    @ViewBuilder private func row(_ item: TimelineItem) -> some View {
        switch item {
        case .walk(let w): walkRow(w)
        case .tap(let events): tapRow(events)
        }
    }

    private func walkRow(_ w: WalkSession) -> some View {
        let walking = w.end == nil && Date.now.timeIntervalSince(w.start) < 4 * 3600
        return HStack(spacing: 10) {
            Image(systemName: "figure.walk")
                .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                .frame(width: 34, height: 34).background(Circle().fill(Theme.green))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Text(w.start, format: .dateTime.hour().minute())
                    Text("〜")
                    if let end = w.end { Text(end, format: .dateTime.hour().minute()) }
                }
                .font(Theme.font(15)).monospacedDigit().foregroundStyle(Theme.text)
                Group {
                    if let m = w.minutes {
                        Text("おさんぽ \(WalkLog.durationText(minutes: m))")
                    } else if walking {
                        Text("おさんぽ中")
                    } else {
                        Text("おわりの きろくなし")
                    }
                }
                .font(Theme.font(14)).foregroundStyle(walking || w.minutes != nil ? Theme.green : Theme.muted)
            }
            Spacer(minLength: 4)
            faces(w.dogIDs)
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.green.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.green.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func tapRow(_ events: [WalkEvent]) -> some View {
        let first = events[0]
        return HStack(spacing: 10) {
            Text(first.date, format: .dateTime.hour().minute())
                .font(Theme.font(15)).monospacedDigit().foregroundStyle(Theme.text)
                .frame(minWidth: 48, alignment: .leading)
            Text("\(first.kind.emoji) \(first.kind.label)").font(Theme.font(15)).foregroundStyle(Theme.text)
            Spacer(minLength: 4)
            if !first.author.isEmpty {
                Text(first.author).font(Theme.font(11)).foregroundStyle(Theme.muted).lineLimit(1)
            }
            faces(events.map(\.dogID))
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card))
        .accessibilityElement(children: .combine)
    }

    private func faces(_ ids: [UUID]) -> some View {
        let dogs = model.dogs.filter { ids.contains($0.id) }
        return HStack(spacing: 4) {
            HStack(spacing: -8) {
                ForEach(dogs.prefix(3)) { DogFace(dog: $0, size: 26) }
            }
            Text(dogs.count == 1 ? dogs[0].name : "\(dogs.count)ひき")
                .font(Theme.font(12)).foregroundStyle(Theme.muted).lineLimit(1)
        }
    }
}

/// Fix a walk's start / end time (for every dog on it), add a missing end, or delete it.
struct WalkEditView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let walk: WalkSession
    @State private var start = Date.now
    @State private var hasEnd = true
    @State private var end = Date.now
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("はじまり") {
                    DatePicker("はじまり", selection: $start, in: ...Date.now.addingTimeInterval(60))
                }
                Section("おわり") {
                    Toggle("おわりの じこく", isOn: $hasEnd)
                    if hasEnd {
                        DatePicker("おわり", selection: $end, in: start...Date.now.addingTimeInterval(60))
                    }
                }
                if hasEnd {
                    Section {
                        Text("おさんぽ \(WalkLog.durationText(from: start, to: end))").foregroundStyle(Theme.green)
                    }
                }
                Section("だれと") {
                    Text(model.dogs.filter { walk.dogIDs.contains($0.id) }.map(\.name).joined(separator: "・"))
                }
                Section {
                    Button("この おさんぽを けす", role: .destructive) { confirmDelete = true }
                }
            }
            .font(Theme.font(16))
            .navigationTitle("おさんぽを なおす")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("ほぞん") { save() } }
            }
            .confirmationDialog("この おさんぽを けしますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("けす", role: .destructive) {
                    model.remove(walk.eventIDs)
                    dismiss()
                }
            }
            .onAppear {
                start = walk.start
                hasEnd = walk.end != nil || Date.now.timeIntervalSince(walk.start) > 4 * 3600
                end = walk.end ?? min(Date.now, walk.start.addingTimeInterval(30 * 60))
            }
        }
    }

    private func save() {
        model.setDate(walk.startEventIDs, to: start)
        if hasEnd {
            let endDate = max(end, start)
            if walk.endEventIDs.isEmpty {
                model.add(WalkLog.makeEvents(kind: .walkEnd, dogIDs: walk.dogIDs, date: endDate, author: model.authorName))
            } else {
                model.setDate(walk.endEventIDs, to: endDate)
            }
        } else if !walk.endEventIDs.isEmpty {
            model.remove(walk.endEventIDs)
        }
        dismiss()
    }
}
