import SwiftUI
import WalkCore

/// きろく: every record by day. Tap to fix the time, kind or dog; swipe to delete; + to add one later.
struct HistoryView: View {
    @EnvironmentObject var model: AppModel
    @State private var editing: WalkEvent?
    @State private var adding = false

    private struct Day: Identifiable {
        var id: Date
        var events: [WalkEvent]
    }

    private var days: [Day] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: model.events) { cal.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { Day(id: $0, events: groups[$0]!.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        NavigationStack {
            List {
                if model.events.isEmpty {
                    Text("まだ きろくが ありません").font(Theme.font(15)).foregroundStyle(Theme.muted)
                }
                ForEach(days) { day in
                    let events = day.events
                    Section {
                        ForEach(events) { e in
                            Button { editing = e } label: { EventRow(event: e) }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 3, leading: 12, bottom: 3, trailing: 12))
                        }
                        .onDelete { offsets in model.remove(offsets.map { events[$0].id }) }
                    } header: {
                        Text(day.id, format: .dateTime.year().month().day().weekday(.abbreviated))
                            .font(Theme.font(14)).foregroundStyle(Theme.text)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
            .sheet(item: $editing) { e in EventEditView(original: e) }
            .sheet(isPresented: $adding) { EventEditView(original: nil) }
        }
    }
}

/// Fix one record, or add one afterwards (original == nil).
struct EventEditView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let original: WalkEvent?
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
                                DogFace(avatar: dog.avatar, size: 32)
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
