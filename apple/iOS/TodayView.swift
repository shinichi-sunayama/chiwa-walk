import SwiftUI
import WalkCore

/// きょう: pick the dogs walking now, one-tap buttons, "last poop N hours ago" per dog, today's list.
struct TodayView: View {
    @EnvironmentObject var model: AppModel
    @State private var addingDog = false
    @State private var undoTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if model.dogs.isEmpty {
                        firstDogCard
                    } else {
                        dogChips
                        walkBar
                        buttons
                        statusCards
                        todayList
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("おさんぽ帳")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottom) { undoBanner }
            .sheet(isPresented: $addingDog) { DogEditView(dog: nil) }
            .onChange(of: model.lastRecord) { _, new in scheduleUndoHide(new) }
        }
    }

    // MARK: First run

    private var firstDogCard: some View {
        VStack(spacing: 14) {
            DogFace(avatar: .ohagi, size: 120)
            Text("ようこそ！").font(Theme.font(24)).foregroundStyle(Theme.text)
            Text("まずは いっしょに おさんぽする\nわんちゃんを とうろくしよう")
                .font(Theme.font(16)).multilineTextAlignment(.center).foregroundStyle(Theme.muted)
            Button { addingDog = true } label: {
                Text("わんちゃんを とうろく").font(Theme.font(20)).padding(.vertical, 14)
            }
            .buttonStyle(LipButtonStyle(fill: Theme.orange, lip: Theme.orangeLip))
            .frame(height: 64)
            Text("ログインは いりません。きろくは この iPhone の中に ほぞんされます。")
                .font(Theme.font(12)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(Theme.card))
        .padding(.top, 40)
    }

    // MARK: Dogs walking now

    private var dogChips: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("いっしょの わんちゃん").font(Theme.font(13)).foregroundStyle(Theme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.dogs) { dog in
                        let on = model.selectedDogIDs.contains(dog.id)
                        Button {
                            if on { model.selectedDogIDs.remove(dog.id) } else { model.selectedDogIDs.insert(dog.id) }
                        } label: {
                            VStack(spacing: 4) {
                                DogFace(dog: dog, size: 56, selected: on)
                                Text(dog.name).font(Theme.font(13)).foregroundStyle(on ? Theme.text : Theme.muted).lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(dog.name)\(on ? "（えらんでいる）" : "")")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Walk start / end

    private var walkingSince: Date? {
        model.selectedDogs.compactMap { WalkLog.walkInProgress(dog: $0.id, in: model.events, now: .now) }.min()
    }

    private var walkBar: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack {
                if let start = walkingSince {
                    Text("おさんぽ中　\(WalkLog.durationText(from: start, to: context.date))")
                        .font(Theme.font(17)).foregroundStyle(Theme.green)
                    Spacer()
                    Button("おわり") { model.record(.walkEnd) }
                        .font(Theme.font(17)).buttonStyle(.borderedProminent).tint(Theme.green)
                } else {
                    Spacer()
                    Button { model.record(.walkStart) } label: {
                        Label("おさんぽ スタート", systemImage: "figure.walk").font(Theme.font(17))
                    }
                    .buttonStyle(.bordered).tint(Theme.green)
                    Spacer()
                }
            }
            .disabled(model.selectedDogIDs.isEmpty)
        }
    }

    // MARK: One-tap buttons

    private var buttons: some View {
        VStack(spacing: 6) {
            // Two buttons are extra tall; with おみず / ごはん turned on they share rows of two.
            let rows = EventKind.rows(model.buttons)
            let height: CGFloat = rows.count == 1 ? 150 : 104
            VStack(spacing: 14) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { kind in
                            Button { model.record(kind) } label: {
                                VStack(spacing: 4) {
                                    KindIcon(kind: kind, size: rows.count == 1 ? 46 : 34)
                                    Text(kind.label).font(Theme.font(rows.count == 1 ? 24 : 20))
                                }
                            }
                            .buttonStyle(LipButtonStyle(fill: kind.fill, lip: kind.lip, foreground: kind.ink))
                            .frame(height: height)
                        }
                    }
                }
            }
            .disabled(model.selectedDogIDs.isEmpty)
            .opacity(model.selectedDogIDs.isEmpty ? 0.5 : 1)
            if model.selectedDogIDs.isEmpty {
                Text("うえで わんちゃんを えらんでね").font(Theme.font(13)).foregroundStyle(Theme.red)
            }
        }
    }

    // MARK: Per-dog facts

    private var statusCards: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(spacing: 10) {
                ForEach(model.dogs) { dog in
                    HStack(spacing: 12) {
                        DogFace(dog: dog, size: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(dog.name).font(Theme.font(16)).foregroundStyle(Theme.text)
                            factLine(.poop, dog: dog, now: context.date)
                            factLine(.pee, dog: dog, now: context.date)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                }
            }
        }
    }

    private func factLine(_ kind: EventKind, dog: Dog, now: Date) -> some View {
        let last = WalkLog.last(kind, dog: dog.id, in: model.events, now: now)
        let count = WalkLog.count(kind, dog: dog.id, in: model.events, on: now, calendar: .current)
        let since = last.map { WalkLog.elapsedText(since: $0.date, now: now) } ?? "まだ きろくなし"
        return Text("\(kind.emoji) \(kind.label)　\(since)　（きょう \(count)回）")
            .font(Theme.font(13)).foregroundStyle(Theme.muted)
    }

    // MARK: Today's list

    private var todayList: some View {
        let today = WalkLog.events(on: .now, in: model.events, calendar: .current)
        return VStack(alignment: .leading, spacing: 8) {
            Text("きょうの きろく").font(Theme.font(15)).foregroundStyle(Theme.text)
            if today.isEmpty {
                Text("まだ ありません").font(Theme.font(13)).foregroundStyle(Theme.muted)
            }
            ForEach(today) { e in
                EventRow(event: e)
                    .contextMenu {
                        Button("けす", systemImage: "trash", role: .destructive) { model.remove([e.id]) }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 80)
    }

    // MARK: Undo

    @ViewBuilder private var undoBanner: some View {
        if let made = model.lastRecord, let first = made.first {
            let names = made.compactMap { model.dog($0.dogID)?.name }.joined(separator: "・")
            HStack {
                Text("\(names)　\(first.kind.label) ✓").font(Theme.font(15)).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                Button("とりけす") { model.undoLastRecord() }.font(Theme.font(15)).buttonStyle(.bordered)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
            .padding(12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func scheduleUndoHide(_ record: [WalkEvent]?) {
        undoTask?.cancel()
        guard let record else { return }
        undoTask = Task {
            try? await Task.sleep(for: .seconds(6))
            if !Task.isCancelled, model.lastRecord == record {
                withAnimation { model.lastRecord = nil }
            }
        }
    }
}

/// One line of the log: time, dog, kind, who.
struct EventRow: View {
    @EnvironmentObject var model: AppModel
    var event: WalkEvent
    var showDate = false

    var body: some View {
        HStack(spacing: 10) {
            Text(event.date, format: showDate ? .dateTime.month().day().hour().minute() : .dateTime.hour().minute())
                .font(Theme.font(15)).monospacedDigit().foregroundStyle(Theme.text)
                .frame(minWidth: 52, alignment: .leading)
            if let dog = model.dog(event.dogID) {
                DogFace(dog: dog, size: 26)
                Text(dog.name).font(Theme.font(14)).foregroundStyle(Theme.text).lineLimit(1)
            }
            Text("\(event.kind.emoji) \(event.kind.label)").font(Theme.font(14)).foregroundStyle(Theme.text)
            Spacer()
            if !event.author.isEmpty {
                Text(event.author).font(Theme.font(12)).foregroundStyle(Theme.muted).lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
    }
}
