import SwiftUI

@main
struct OsanpoApp: App {
    @StateObject private var model: AppModel
    private let sync = PhoneSync()

    init() {
        let persistence = PersistenceController()
        _model = StateObject(wrappedValue: AppModel(persistence: persistence))
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

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("きょう", systemImage: "pawprint.fill") }
            HistoryView()
                .tabItem { Label("きろく", systemImage: "list.bullet") }
            SettingsView()
                .tabItem { Label("せってい", systemImage: "gearshape") }
        }
        .tint(Theme.orange)
        .font(Theme.font(16))
    }
}
