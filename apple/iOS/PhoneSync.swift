import Foundation
import WalkCore
import WatchConnectivity

/// iPhone side of the Watch link.
/// - Receives the Watch's records (queued transferUserInfo, so nothing is lost while apart) and stores them.
/// - Sends the Watch the latest dogs and recent events (applicationContext: only the newest matters).
final class PhoneSync: NSObject, WCSessionDelegate {
    private weak var model: AppModel?

    @MainActor
    func start(model: AppModel) {
        self.model = model
        model.onChange = { [weak self] in self?.sendSnapshot() }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    @MainActor
    func sendSnapshot() {
        guard WCSession.isSupported(), let model else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        let now = Date()
        let snapshot = WatchSync.Snapshot(
            dogs: model.dogs,
            events: WatchSync.snapshotEvents(dogs: model.dogs, events: model.events, now: now),
            madeAt: now)
        if var dict = try? WatchSync.encode(snapshot) {
            dict["author"] = model.authorName // records made on the Watch carry the same name
            try? session.updateApplicationContext(dict)
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.sendSnapshot() }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.sendSnapshot() }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let envelope = WatchSync.decode(WatchSync.OperationEnvelope.self, from: userInfo) else { return }
        Task { @MainActor in self.model?.apply(envelope.operation) }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate() // switching to another Apple Watch
    }
}
