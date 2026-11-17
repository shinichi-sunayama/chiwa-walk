import SwiftUI

@main
struct OsanpoApp: App {
    @StateObject private var model: AppModel
    private let sync = PhoneSync()

    init() {
        let persistence = PersistenceController(inMemory: ScreenshotMode.isOn)
        let model = AppModel(persistence: persistence)
        if ScreenshotMode.isOn { model.seedDemo() }
        _model = StateObject(wrappedValue: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onAppear { sync.start(model: model) }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var tab = ScreenshotMode.isOn ? ScreenshotMode.tab : 0

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("きょう", systemImage: "pawprint.fill") }.tag(0)
            HistoryView()
                .tabItem { Label("きろく", systemImage: "list.bullet") }.tag(1)
            SettingsView()
                .tabItem { Label("せってい", systemImage: "gearshape") }.tag(2)
        }
        .tint(Theme.orange)
        .font(Theme.font(16))
    }
}
