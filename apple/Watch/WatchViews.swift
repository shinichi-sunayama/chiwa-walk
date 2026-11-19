import SwiftUI
import WalkCore

@main
struct OsanpoWatchApp: App {
    @StateObject private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            WatchRootView().environmentObject(store)
        }
    }
}

struct WatchRootView: View {
    @EnvironmentObject var store: WatchStore
    @State private var page = UserDefaults.standard.integer(forKey: "shotPage") // screenshots only

    var body: some View {
        NavigationStack {
            if store.dogs.isEmpty {
                VStack(spacing: 8) {
                    DogFace(avatar: .ohagi, size: 56)
                    Text("iPhone の おさんぽ帳で わんちゃんを とうろくしてね")
                        .font(Theme.font(14)).multilineTextAlignment(.center)
                }
                .padding(.horizontal, 6)
            } else {
                TabView(selection: $page) {
                    WatchRecordView().tag(0)
                    WatchStatusView().tag(1)
                }
                .tabViewStyle(.verticalPage)
            }
        }
    }
}

/// Page 1: who the tap is for (big, at the top) and the buttons. Buttons show pictures only (no words on
/// the wrist). One tap = recorded for every selected dog, with a wrist tap to confirm.
struct WatchRecordView: View {
    @EnvironmentObject var store: WatchStore
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        let rows = EventKind.rows(store.buttons)
        VStack(spacing: 6) {
            NavigationLink { WatchDogPicker() } label: { target }
                .buttonStyle(.plain)
                .accessibilityLabel("\(store.selectionLabel) に きろく。えらびなおす")
            if let start = walkStart { walkTimer(start) }
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { kind in button(kind, big: rows.count == 1) }
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 4)
        .overlay { if let made = store.lastRecord { confirmation(made) } }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { walkButton }
        }
        .onChange(of: store.lastRecord) { _, new in scheduleHide(new) }
    }

    private func button(_ kind: EventKind, big: Bool) -> some View {
        Button { store.record(kind) } label: {
            KindIcon(kind: kind, size: big ? 52 : 30)
        }
        .buttonStyle(LipButtonStyle(fill: kind.fill, lip: kind.lip, corner: 16, depth: 4, foreground: kind.ink))
        .disabled(store.selectedDogIDs.isEmpty)
        .opacity(store.selectedDogIDs.isEmpty ? 0.4 : 1)
        .accessibilityLabel(kind.label)
    }

    /// 「おはぎ」 with the face, in an orange pill: who the next tap records for. Tap to change.
    private var target: some View {
        HStack(spacing: 5) {
            HStack(spacing: -8) {
                ForEach(store.selectedDogs.prefix(3)) { dog in DogFace(dog: dog, size: 24) }
            }
            Text(store.selectedDogIDs.isEmpty ? "わんちゃんを えらぶ" : store.selectionLabel)
                .font(Theme.font(14)).lineLimit(1).minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold)).opacity(0.7)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.orange.opacity(0.35)))
        .overlay(Capsule().stroke(Theme.orange, lineWidth: 1.5))
    }

    /// Start of the walk in progress for the chosen dogs (the earliest), or nil.
    private var walkStart: Date? {
        store.selectedDogs.compactMap { WalkLog.walkInProgress(dog: $0.id, in: store.events, now: .now) }.min()
    }

    private var walking: Bool { walkStart != nil }

    /// 「🚶 12:34 おさんぽ中」, counting up by itself.
    private func walkTimer(_ start: Date) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
            Text(start, style: .timer).monospacedDigit()
            Spacer(minLength: 0)
            Text("おさんぽ中")
        }
        .font(Theme.font(13))
        .foregroundStyle(Theme.green)
        .padding(.horizontal, 6)
        .accessibilityElement(children: .combine)
    }

    private var walkButton: some View {
        Button { store.record(walking ? .walkEnd : .walkStart) } label: {
            Image(systemName: walking ? "house.fill" : "figure.walk")
                .foregroundStyle(walking ? Theme.orange : Theme.green)
        }
        .disabled(store.selectedDogIDs.isEmpty)
        .accessibilityLabel(walking ? "おさんぽ おわり" : "おさんぽ スタート")
    }

    private func confirmation(_ made: [WalkEvent]) -> some View {
        let names = made.compactMap { store.dog($0.dogID)?.name }.joined(separator: "・")
        let kind = made.first?.kind ?? .pee
        return VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 34)).foregroundStyle(Theme.green)
            HStack(spacing: -6) {
                ForEach(made.compactMap { store.dog($0.dogID) }.prefix(3)) { dog in DogFace(dog: dog, size: 26) }
            }
            switch kind {
            case .walkStart:
                Text("おさんぽ スタート").font(Theme.font(15)).foregroundStyle(Theme.green)
            case .walkEnd:
                let minutes = Walks.sessions(in: store.events).first { $0.endEventIDs.contains(made[0].id) }?.minutes
                Text(minutes.map { "おさんぽ \(WalkLog.durationText(minutes: $0))" } ?? "おさんぽ おわり")
                    .font(Theme.font(15)).foregroundStyle(Theme.green)
            default:
                KindIcon(kind: kind, size: 20)
            }
            Text(names).font(Theme.font(13)).lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center)
            Button("とりけす") { store.undoLastRecord() }
                .font(Theme.font(14))
                .tint(Theme.red)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.88))
        .onTapGesture { store.lastRecord = nil }
    }

    private func scheduleHide(_ record: [WalkEvent]?) {
        hideTask?.cancel()
        guard let record else { return }
        hideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled, store.lastRecord == record {
                withAnimation { store.lastRecord = nil }
            }
        }
    }
}

/// Choose who the buttons record for. Tap a dog = that dog only (and back). 「みんな」 = every dog.
/// The check marks below add or remove one dog, to record for several.
struct WatchDogPicker: View {
    @EnvironmentObject var store: WatchStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(store.dogs) { dog in
                    let on = store.selectedDogIDs == [dog.id]
                    Button {
                        store.selectedDogIDs = DogSelection.only(dog.id)
                        dismiss()
                    } label: {
                        HStack {
                            DogFace(dog: dog, size: 30, selected: on)
                            Text(dog.name).font(Theme.font(15)).lineLimit(1)
                            Spacer()
                            if on { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.orange) }
                        }
                    }
                }
                if store.dogs.count >= 2 {
                    Button {
                        store.selectedDogIDs = DogSelection.all(store.dogs)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "pawprint.fill").foregroundStyle(Theme.orange).frame(width: 30)
                            Text("みんな").font(Theme.font(15))
                            Spacer()
                            if DogSelection.isAll(store.selectedDogIDs, dogs: store.dogs) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.orange)
                            }
                        }
                    }
                }
            }
            if store.dogs.count >= 3 {
                Section("えらんで まとめる") {
                    ForEach(store.dogs) { dog in
                        let on = store.selectedDogIDs.contains(dog.id)
                        Button {
                            let next = DogSelection.toggled(dog.id, in: store.selectedDogIDs)
                            if !next.isEmpty { store.selectedDogIDs = next }
                        } label: {
                            HStack {
                                Text(dog.name).font(Theme.font(14)).lineLimit(1)
                                Spacer()
                                Image(systemName: on ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(on ? Theme.orange : .secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("だれの きろく？")
    }
}

/// Page 2: time since the last poop / pee for each dog and today's count.
struct WatchStatusView: View {
    @EnvironmentObject var store: WatchStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    let today = Walks.summaries(events: store.events, calendar: .current)[Calendar.current.startOfDay(for: context.date)]
                    Label(today.map(Walks.walkText) ?? "おさんぽ なし", systemImage: "figure.walk")
                        .font(Theme.font(13)).foregroundStyle(Theme.green)
                    ForEach(store.dogs) { dog in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                DogFace(dog: dog, size: 22)
                                Text(dog.name).font(Theme.font(15)).lineLimit(1)
                                if let start = WalkLog.walkInProgress(dog: dog.id, in: store.events, now: context.date) {
                                    Text("🐾\(WalkLog.durationText(from: start, to: context.date))")
                                        .font(Theme.font(11)).foregroundStyle(Theme.green)
                                }
                            }
                            line(.poop, dog: dog, now: context.date)
                            line(.pee, dog: dog, now: context.date)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func line(_ kind: EventKind, dog: Dog, now: Date) -> some View {
        let last = WalkLog.last(kind, dog: dog.id, in: store.events, now: now)
        let count = WalkLog.count(kind, dog: dog.id, in: store.events, on: now, calendar: .current)
        let since = last.map { WalkLog.elapsedText(since: $0.date, now: now) } ?? "―"
        return Text("\(kind.emoji) \(since)・きょう\(count)回")
            .font(Theme.font(12)).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
    }
}
