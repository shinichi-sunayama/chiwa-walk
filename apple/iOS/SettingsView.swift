import PhotosUI
import SwiftUI
import WalkCore

/// せってい: dogs, the user's name, a list for the vet, and notes (no health advice; data stays on the device).
struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var editingDog: Dog?
    @State private var addingDog = false
    @State private var exportDays = 14

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(model.dogs) { dog in
                        Button { editingDog = dog } label: {
                            HStack(spacing: 12) {
                                DogFace(dog: dog, size: 40)
                                Text(dog.name).foregroundStyle(Theme.text)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                            }
                        }
                    }
                    .onMove { model.moveDogs(from: $0, to: $1) }
                    Button { addingDog = true } label: { Label("わんちゃんを たす", systemImage: "plus.circle.fill") }
                } header: {
                    HStack {
                        Text("わんちゃん")
                        Spacer()
                        if model.dogs.count > 1 { EditButton().font(Theme.font(13)) }
                    }
                }

                Section {
                    Toggle("💧 おみず", isOn: extraBinding(.water))
                    Toggle("🍽️ ごはん", isOn: extraBinding(.food))
                } header: {
                    Text("きろくボタン")
                } footer: {
                    Text("おしっこ・うんちは いつも でます。おみず・ごはんも きろくしたいときは オンに（Apple Watch にも はんえい）。")
                }

                Section {
                    TextField("れい：パパ、ママ、たろう", text: $model.authorName)
                } header: {
                    Text("あなたの なまえ")
                } footer: {
                    Text("きろくに「だれが つけたか」として のこります（家族と きょうゆうするときに べんり）。")
                }

                Section {
                    Picker("きかん", selection: $exportDays) {
                        Text("7日").tag(7)
                        Text("14日").tag(14)
                        Text("30日").tag(30)
                        Text("90日").tag(90)
                    }
                    ShareLink(item: dailyText, subject: Text("おさんぽ帳のきろく")) {
                        Label("いちらんを おくる（文章）", systemImage: "doc.text")
                    }
                    if let url = csvFile {
                        ShareLink(item: url) { Label("表に して おくる（CSV）", systemImage: "tablecells") }
                    }
                } header: {
                    Text("どうぶつ病院で みせる いちらん")
                } footer: {
                    Text("日にちごとの じこくと 回数だけを まとめます。")
                }

                Section("このアプリについて") {
                    note("きろくと わんちゃんの しゃしんは この iPhone の中だけに ほぞんされます。ログインは いりません。いち（GPS）は つかいません。")
                    note("このアプリは きろくだけを します。けんこうの はんだんは しません。きになるときは どうぶつ病院に そうだんしてね。")
                    LabeledContent("バージョン", value: version)
                    note("おはぎきなこ工房　フォント：M PLUS Rounded 1c（SIL Open Font License 1.1）")
                    if let error = PersistenceController.loadError ?? model.saveError {
                        Text("ほぞんの エラー：\(error)").font(Theme.font(12)).foregroundStyle(Theme.red)
                    }
                }
            }
            .font(Theme.font(16))
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("せってい")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingDog) { DogEditView(dog: $0) }
            .sheet(isPresented: $addingDog) { DogEditView(dog: nil) }
        }
    }

    private func extraBinding(_ kind: EventKind) -> Binding<Bool> {
        Binding(
            get: { model.extraButtons.contains(kind) },
            set: { on in
                if on { model.extraButtons.insert(kind) } else { model.extraButtons.remove(kind) }
            })
    }

    private func note(_ s: String) -> some View {
        Text(s).font(Theme.font(13)).foregroundStyle(Theme.muted)
    }

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v)（\(b)）"
    }

    private var exportEvents: [WalkEvent] {
        let since = Calendar.current.date(byAdding: .day, value: -(exportDays - 1), to: Calendar.current.startOfDay(for: .now))!
        return model.events.filter { $0.date >= since }
    }

    private var dailyText: String {
        "おさんぽ帳のきろく（さいきん \(exportDays)日）\n\n" + Export.dailyText(dogs: model.dogs, events: exportEvents, timeZone: .current)
    }

    private var csvFile: URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("osanpo-\(exportDays)days.csv")
        let text = Export.csv(dogs: model.dogs, events: exportEvents, timeZone: .current)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

/// Add a dog (dog == nil) or change its name / picture / delete it.
struct DogEditView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let dog: Dog?
    @State private var name = ""
    @State private var avatar = Avatar.ohagi
    @State private var photo: Data?
    @State private var pickedItem: PhotosPickerItem?
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("なまえ") {
                    TextField("れい：おはぎ", text: $name)
                }
                Section {
                    HStack(spacing: 16) {
                        DogFace(avatar: avatar, photo: photo, size: 72)
                        VStack(alignment: .leading, spacing: 8) {
                            PhotosPicker(selection: $pickedItem, matching: .images) {
                                Label(photo == nil ? "しゃしんを えらぶ" : "しゃしんを かえる", systemImage: "photo")
                            }
                            if photo != nil {
                                Button("しゃしんを やめる", role: .destructive) { photo = nil }
                            }
                        }
                    }
                } header: {
                    Text("しゃしん")
                } footer: {
                    Text("まんなかを まるく きりとります。しゃしんは この iPhone の中だけに ほぞんされます。")
                }
                Section(photo == nil ? "え" : "え（しゃしんが ないときに つかいます）") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(Avatar.allCases, id: \.self) { a in
                            Button { avatar = a } label: {
                                VStack(spacing: 4) {
                                    DogFace(avatar: a, size: 64, selected: avatar == a)
                                    Text(a.displayName).font(Theme.font(12)).foregroundStyle(Theme.text)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
                if dog != nil {
                    Section {
                        Button("この わんちゃんを けす", role: .destructive) { confirmDelete = true }
                    } footer: {
                        Text("この わんちゃんの きろくも ぜんぶ きえます。")
                    }
                }
            }
            .font(Theme.font(16))
            .navigationTitle(dog == nil ? "わんちゃんを とうろく" : "わんちゃん")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("ほぞん") { save() }.disabled(trimmed.isEmpty)
                }
            }
            .confirmationDialog("\(dog?.name ?? "")と その きろくを ぜんぶ けしますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("けす", role: .destructive) {
                    if let dog { model.deleteDog(dog.id) }
                    dismiss()
                }
            }
            .onAppear {
                if let dog {
                    name = dog.name
                    avatar = dog.avatar
                    photo = dog.photo
                }
            }
            .onChange(of: pickedItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let square = PhotoTools.squareJPEG(from: data, side: 320) {
                        photo = square
                    }
                    pickedItem = nil
                }
            }
        }
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func save() {
        if var d = dog {
            d.name = trimmed
            d.avatar = avatar
            d.photo = photo
            model.updateDog(d)
        } else {
            model.addDog(name: trimmed, avatar: avatar, photo: photo)
        }
        dismiss()
    }
}
