import Foundation
import WalkCore

/// App Store screenshots only (simulator, launch arguments from tools/take_screenshots.sh):
/// -shotDemo YES  uses an in-memory store filled with DemoData (nothing is saved)
/// -shotTab N     opens tab N (0 きょう, 1 きろく, 2 せってい)
enum ScreenshotMode {
    static var isOn: Bool { UserDefaults.standard.bool(forKey: "shotDemo") }
    static var tab: Int { UserDefaults.standard.integer(forKey: "shotTab") }
}

extension AppModel {
    func seedDemo() {
        for d in DemoData.dogs {
            let obj = CDDog(context: persistence.container.viewContext)
            obj.id = d.id
            obj.name = d.name
            obj.avatar = d.avatar.rawValue
            obj.order = Int64(d.order)
            obj.createdAt = .now
        }
        try? persistence.container.viewContext.save()
        reload()
        add(DemoData.events(now: .now))
        selectedDogIDs = [DemoData.ohagiID]
        authorName = "ママ"
    }
}
