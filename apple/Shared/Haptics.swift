#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

/// Vibrations that confirm a record without looking at the screen.
/// On the Watch the wrist tap is the main "it worked" signal (spec 3.2 ①).
enum Haptics {
    enum Kind { case recorded, undone, walk }

    static func play(_ kind: Kind) {
        #if os(watchOS)
        let device = WKInterfaceDevice.current()
        switch kind {
        case .recorded: device.play(.success)
        case .undone: device.play(.retry)
        case .walk: device.play(.start)
        }
        #else
        switch kind {
        case .recorded: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .undone: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .walk: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        #endif
    }
}
