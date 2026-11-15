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
                TabView {
                    WatchRecordView()
                    WatchStatusView()
                }
                .tabViewStyle(.verticalPage)
            }
        }
    }
}

/// Page 1: four big buttons. One tap = recorded for every selected dog, with a wrist tap to confirm.
struct WatchRecordView: View {
    @EnvironmentObject var store: WatchStore
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        let disabled = store.selectedDogIDs.isEmpty
        Grid(horizontalSpacing: 6, verticalSpacing: 7) {
            GridRow {
                button(.pee)
                button(.poop)
            }
            GridRow {
                button(.water)
                button(.food)
            }
        }
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .padding(.horizontal, 2)
        .padding(.bottom, 4)
        .overlay { if let made = store.lastRecord { confirmation(made) } }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink { WatchDogPicker() } label: { dogFaces }
                    .accessibilityLabel("いっしょの わんちゃんを えらぶ")
            }
            ToolbarItem(placement: .topBarTrailing) { walkButton }
        }
        .onChange(of: store.lastRecord) { _, new in scheduleHide(new) }
    }

    private func button(_ kind: EventKind) -> some View {
        Button { store.record(kind) } label: {
            VStack(spacing: 0) {
                Text(kind.emoji).font(.system(size: 26))
                Text(kind.label).font(Theme.font(14)).lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(LipButtonStyle(fill: kind.fill, lip: kind.lip, corner: 16, depth: 4, foreground: kind.ink))
    }

    private var dogFaces: some View {
        HStack(spacing: -6) {
            let shown = store.selectedDogs.prefix(3)
            if shown.isEmpty {
                Image(systemName: "pawprint").foregroundStyle(Theme.red)
            }
            ForEach(Array(shown)) { dog in DogFace(avatar: dog.avatar, size: 24) }
            if store.selectedDogs.count > 3 {
                Text("+\(store.selectedDogs.count - 3)").font(Theme.font(11)).padding(.leading, 8)
            }
        }
    }

    private var walking: Bool {
        store.selectedDogs.contains { WalkLog.walkInProgress(dog: $0.id, in: store.events, now: .now) != nil }
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
            Text("\(kind.emoji) \(kind.label)").font(Theme.font(17))
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

/// Choose which dogs are walking now (remembered for next time).
struct WatchDogPicker: View {
    @EnvironmentObject var store: WatchStore

    var body: some View {
        List(store.dogs) { dog in
            let on = store.selectedDogIDs.contains(dog.id)
            Button {
                if on { store.selectedDogIDs.remove(dog.id) } else { store.selectedDogIDs.insert(dog.id) }
            } label: {
                HStack {
                    DogFace(avatar: dog.avatar, size: 30, selected: on)
                    Text(dog.name).font(Theme.font(15))
                    Spacer()
                    if on { Image(systemName: "checkmark").foregroundStyle(Theme.orange) }
                }
            }
        }
        .navigationTitle("いっしょの子")
    }
}

/// Page 2: time since the last poop / pee for each dog and today's count.
struct WatchStatusView: View {
    @EnvironmentObject var store: WatchStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(store.dogs) { dog in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                DogFace(avatar: dog.avatar, size: 22)
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
