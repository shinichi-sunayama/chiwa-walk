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

    /// Tap a dog = switch to that dog only. Long press = add / remove (to record for several at once).
    /// 「みんな」 = every dog. The choice is shown big, so it is always clear who a tap records for.
    private var dogChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(model.dogs) { dog in
                        dogChip(dog)
                    }
                    if model.dogs.count >= 2 { allChip }
                }
                .padding(.vertical, 4)
            }
            if model.dogs.count >= 2 {
                Text("タップで きりかえ・ながおしで ふやす")
                    .font(Theme.font(12)).foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dogChip(_ dog: Dog) -> some View {
        let on = model.selectedDogIDs.contains(dog.id)
        return VStack(spacing: 4) {
            DogFace(dog: dog, size: 56, selected: on)
                .overlay(alignment: .bottomTrailing) {
                    if on {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20)).foregroundStyle(.white, Theme.orange)
                            .offset(x: 4, y: 4)
                    }
                }
            Text(dog.name).font(Theme.font(13)).foregroundStyle(on ? Theme.text : Theme.muted).lineLimit(1)
        }
        .frame(width: 76)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 18).fill(on ? Theme.orange.opacity(0.18) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(on ? Theme.orange : Color.clear, lineWidth: 2))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.snappy) { model.selectedDogIDs = DogSelection.only(dog.id) }
        }
        .onLongPressGesture {
            let next = DogSelection.toggled(dog.id, in: model.selectedDogIDs)
            guard !next.isEmpty else { return } // keep at least one dog
            withAnimation(.snappy) { model.selectedDogIDs = next }
            Haptics.play(.walk)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dog.name)\(on ? "（えらんでいる）" : "")")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { model.selectedDogIDs = DogSelection.only(dog.id) }
        .accessibilityAction(named: on ? "はずす" : "ふやす") {
            let next = DogSelection.toggled(dog.id, in: model.selectedDogIDs)
            if !next.isEmpty { model.selectedDogIDs = next }
        }
    }

    private var allChip: some View {
        let on = DogSelection.isAll(model.selectedDogIDs, dogs: model.dogs)
        return Button {
            withAnimation(.snappy) { model.selectedDogIDs = DogSelection.all(model.dogs) }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(on ? Theme.card : Theme.chip)
                    Image(systemName: "pawprint.fill").font(.system(size: 22))
                        .foregroundStyle(on ? Theme.orange : Theme.muted)
                }
                .frame(width: 56, height: 56)
                .overlay(Circle().stroke(on ? Theme.orange : Theme.lip, lineWidth: on ? 3 : 1))
                Text("みんな").font(Theme.font(13)).foregroundStyle(on ? Theme.text : Theme.muted)
            }
            .frame(width: 76)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 18).fill(on ? Theme.orange.opacity(0.18) : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(on ? Theme.orange : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("みんな\(on ? "（えらんでいる）" : "")")
    }

    /// 「おはぎ に きろく」 right above the buttons.
    private var recordTarget: some View {
        HStack(spacing: 6) {
            HStack(spacing: -10) {
                ForEach(model.selectedDogs.prefix(4)) { dog in DogFace(dog: dog, size: 30) }
            }
            Text(model.selectionLabel).font(Theme.font(17)).foregroundStyle(Theme.text)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text("に きろく").font(Theme.font(15)).foregroundStyle(Theme.muted)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
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
        VStack(spacing: 8) {
            if !model.selectedDogIDs.isEmpty { recordTarget }
            // Two buttons are extra tall; with おみず / ごはん turned on they share rows of two.
            let rows = EventKind.rows(model.buttons)
            let height: CGFloat = rows.count == 1 ? 150 : 104
            VStack(spacing: 14) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { kind in
                            Button { model.record(kind) } label: {
                                // Quiet labels: the picture carries the meaning, the word is small.
                                VStack(spacing: 6) {
                                    KindIcon(kind: kind, size: rows.count == 1 ? 58 : 42)
                                    Text(kind.label).font(Theme.font(rows.count == 1 ? 14 : 12)).opacity(0.85)
                                }
                            }
                            .buttonStyle(LipButtonStyle(fill: kind.fill, lip: kind.lip, foreground: kind.ink))
                            .frame(height: height)
                            .accessibilityLabel(kind.label)
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
                        DogFace(dog: dog, size: 44, selected: model.selectedDogIDs.contains(dog.id))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(dog.name).font(Theme.font(16)).foregroundStyle(Theme.text)
                            factLine(.poop, dog: dog, now: context.date)
                            factLine(.pee, dog: dog, now: context.date)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(model.selectedDogIDs.contains(dog.id) ? Theme.orange.opacity(0.6) : .clear, lineWidth: 2))
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
