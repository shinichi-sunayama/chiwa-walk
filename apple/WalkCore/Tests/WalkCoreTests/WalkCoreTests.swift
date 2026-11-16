import XCTest
@testable import WalkCore

final class WalkLogTests: XCTestCase {
    let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = tokyo
        return c
    }

    /// 2026-11-16 at hh:mm in Tokyo.
    func at(_ hour: Int, _ minute: Int = 0, day: Int = 16) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    let ohagi = Dog(name: "おはぎ", avatar: .ohagi, order: 0)
    let kinako = Dog(name: "きなこ", avatar: .kinako, order: 1)

    func testOneTapMakesOneEventPerDogWithSharedGroup() {
        let events = WalkLog.makeEvents(kind: .poop, dogIDs: [ohagi.id, kinako.id], date: at(7), author: "パパ")
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(Set(events.map(\.dogID)), [ohagi.id, kinako.id])
        XCTAssertEqual(Set(events.map(\.groupID)).count, 1)
        XCTAssertEqual(Set(events.map(\.id)).count, 2)
        XCTAssertTrue(events.allSatisfy { $0.kind == .poop && $0.author == "パパ" && $0.date == at(7) })
    }

    func testNoDogsSelectedMakesNothing() {
        XCTAssertTrue(WalkLog.makeEvents(kind: .pee, dogIDs: [], date: at(7), author: "").isEmpty)
    }

    func testLastPicksLatestOfKindForDogAndIgnoresFuture() {
        let events = [
            WalkEvent(dogID: ohagi.id, kind: .poop, date: at(7)),
            WalkEvent(dogID: ohagi.id, kind: .poop, date: at(12)),
            WalkEvent(dogID: ohagi.id, kind: .pee, date: at(13)),
            WalkEvent(dogID: kinako.id, kind: .poop, date: at(14)),
            WalkEvent(dogID: ohagi.id, kind: .poop, date: at(20)), // future
        ]
        XCTAssertEqual(WalkLog.last(.poop, dog: ohagi.id, in: events, now: at(15))?.date, at(12))
        XCTAssertNil(WalkLog.last(.water, dog: ohagi.id, in: events, now: at(15)))
    }

    func testCountUsesCalendarDay() {
        let events = [
            WalkEvent(dogID: ohagi.id, kind: .pee, date: at(23, 50, day: 15)),
            WalkEvent(dogID: ohagi.id, kind: .pee, date: at(0, 10)),
            WalkEvent(dogID: ohagi.id, kind: .pee, date: at(7)),
            WalkEvent(dogID: kinako.id, kind: .pee, date: at(7)),
        ]
        XCTAssertEqual(WalkLog.count(.pee, dog: ohagi.id, in: events, on: at(12), calendar: calendar), 2)
        XCTAssertEqual(WalkLog.events(on: at(12), in: events, calendar: calendar).map(\.date), [at(7), at(7), at(0, 10)])
    }

    func testElapsedText() {
        let now = at(15)
        XCTAssertEqual(WalkLog.elapsedText(since: now.addingTimeInterval(-30), now: now), "たった今")
        XCTAssertEqual(WalkLog.elapsedText(since: now.addingTimeInterval(60), now: now), "たった今")
        XCTAssertEqual(WalkLog.elapsedText(since: at(14, 48), now: now), "12分前")
        XCTAssertEqual(WalkLog.elapsedText(since: at(12), now: now), "3時間前")
        XCTAssertEqual(WalkLog.elapsedText(since: at(11, 55), now: now), "3時間5分前")
        XCTAssertEqual(WalkLog.elapsedText(since: at(15, day: 14), now: now), "2日前")
        XCTAssertEqual(WalkLog.elapsedShort(since: at(11, 55), now: now), "3時間")
        XCTAssertEqual(WalkLog.elapsedShort(since: at(14, 48), now: now), "12分")
        XCTAssertEqual(WalkLog.elapsedShort(since: at(10, day: 13), now: now), "3日")
    }

    func testDurationText() {
        XCTAssertEqual(WalkLog.durationText(from: at(7), to: at(7, 25)), "25分")
        XCTAssertEqual(WalkLog.durationText(from: at(7), to: at(8)), "1時間")
        XCTAssertEqual(WalkLog.durationText(from: at(7), to: at(8, 10)), "1時間10分")
    }

    func testWalkInProgress() {
        var events = [WalkEvent(dogID: ohagi.id, kind: .walkStart, date: at(7))]
        XCTAssertEqual(WalkLog.walkInProgress(dog: ohagi.id, in: events, now: at(7, 20)), at(7))
        XCTAssertNil(WalkLog.walkInProgress(dog: kinako.id, in: events, now: at(7, 20)))
        // Forgotten end: closed after 4 hours.
        XCTAssertNil(WalkLog.walkInProgress(dog: ohagi.id, in: events, now: at(11, 1)))
        events.append(WalkEvent(dogID: ohagi.id, kind: .walkEnd, date: at(7, 30)))
        XCTAssertNil(WalkLog.walkInProgress(dog: ohagi.id, in: events, now: at(7, 40)))
        events.append(WalkEvent(dogID: ohagi.id, kind: .walkStart, date: at(17)))
        XCTAssertEqual(WalkLog.walkInProgress(dog: ohagi.id, in: events, now: at(17, 5)), at(17))
    }

    func testMergeIncomingWinsAndDeletesDrop() {
        let a = WalkEvent(dogID: ohagi.id, kind: .pee, date: at(7))
        var aEdited = a
        aEdited.date = at(8)
        let b = WalkEvent(dogID: ohagi.id, kind: .poop, date: at(9))
        let c = WalkEvent(dogID: kinako.id, kind: .water, date: at(10))
        let merged = WalkLog.merge([a, b], [aEdited, c], deleted: [b.id])
        XCTAssertEqual(merged.map(\.id), [c.id, a.id]) // newest first
        XCTAssertEqual(merged.last?.date, at(8))
        // Merging twice gives the same result (no duplicates).
        XCTAssertEqual(WalkLog.merge(merged, merged), merged)
    }
}

final class ButtonTests: XCTestCase {
    func testStandardButtonsAndOptionalOnes() {
        XCTAssertEqual(EventKind.buttons(extra: []), [.pee, .poop])
        XCTAssertEqual(EventKind.buttons(extra: [.food]), [.pee, .poop, .food])
        XCTAssertEqual(EventKind.buttons(extra: [.food, .water]), [.pee, .poop, .water, .food])
        // Walk start/end are never buttons.
        XCTAssertEqual(EventKind.buttons(extra: [.walkStart]), [.pee, .poop])
    }

    func testRowsOfTwo() {
        XCTAssertEqual(EventKind.rows([.pee, .poop]), [[.pee, .poop]])
        XCTAssertEqual(EventKind.rows([.pee, .poop, .water]), [[.pee, .poop], [.water]])
        XCTAssertEqual(EventKind.rows([.pee, .poop, .water, .food]), [[.pee, .poop], [.water, .food]])
    }
}

final class WatchSyncTests: XCTestCase {
    func testOperationRoundTrip() throws {
        let dog = UUID()
        let events = WalkLog.makeEvents(kind: .water, dogIDs: [dog], date: Date(timeIntervalSince1970: 1_800_000_000), author: "ママ")
        for op in [WatchSync.Operation.add(events), .remove(events.map(\.id))] {
            let dict = try WatchSync.encode(WatchSync.OperationEnvelope(op))
            XCTAssertEqual(WatchSync.decode(WatchSync.OperationEnvelope.self, from: dict)?.operation, op)
        }
    }

    func testSnapshotRoundTripAndBadInput() throws {
        let dogs = [Dog(name: "しらたま", avatar: .shiratama, order: 0, photo: Data([0xFF, 0xD8, 0x01]))]
        let snap = WatchSync.Snapshot(dogs: dogs, events: [], madeAt: Date(timeIntervalSince1970: 1_800_000_000), buttons: [.pee, .poop, .water])
        let dict = try WatchSync.encode(snap)
        XCTAssertEqual(WatchSync.decode(WatchSync.Snapshot.self, from: dict), snap)
        XCTAssertNil(WatchSync.decode(WatchSync.Snapshot.self, from: ["other": 1]))
        // A snapshot from the first prototype (no photo, no buttons) still decodes.
        let old = #"{"version":1,"dogs":[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"きなこ","avatar":"kinako","order":0}],"events":[],"madeAt":1800000000}"#
        let decoded = WatchSync.decode(WatchSync.Snapshot.self, from: [WatchSync.key: Data(old.utf8)])
        XCTAssertEqual(decoded?.dogs.first?.name, "きなこ")
        XCTAssertNil(decoded?.dogs.first?.photo)
        XCTAssertNil(decoded?.buttons)
        XCTAssertNil(WatchSync.decode(WatchSync.Snapshot.self, from: [WatchSync.key: Data("x".utf8)]))
    }

    func testSnapshotKeepsRecentAndLatestOfEachKind() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let dog = Dog(name: "ようかん", avatar: .yokan, order: 0)
        let oldPoop = WalkEvent(dogID: dog.id, kind: .poop, date: now.addingTimeInterval(-10 * 86400))
        let olderPoop = WalkEvent(dogID: dog.id, kind: .poop, date: now.addingTimeInterval(-11 * 86400))
        let oldPee = WalkEvent(dogID: dog.id, kind: .pee, date: now.addingTimeInterval(-5 * 86400))
        let newPee = WalkEvent(dogID: dog.id, kind: .pee, date: now.addingTimeInterval(-3600))
        let newerPee = WalkEvent(dogID: dog.id, kind: .pee, date: now.addingTimeInterval(-60))
        let chosen = WatchSync.snapshotEvents(dogs: [dog], events: [oldPoop, olderPoop, oldPee, newPee, newerPee], now: now)
        XCTAssertEqual(chosen.map(\.id), [newerPee.id, newPee.id, oldPoop.id])
    }
}

final class ExportTests: XCTestCase {
    let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    func testCSV() {
        let dog = Dog(name: "おはぎ, 2さい", avatar: .ohagi, order: 0)
        let t = Date(timeIntervalSince1970: 1_794_783_000) // 2026-11-16 07:50 JST
        let events = [
            WalkEvent(dogID: dog.id, kind: .poop, date: t.addingTimeInterval(120), author: "パパ"),
            WalkEvent(dogID: dog.id, kind: .pee, date: t, author: ""),
        ]
        let csv = Export.csv(dogs: [dog], events: events, timeZone: tokyo)
        XCTAssertEqual(csv, "\u{FEFF}日付,時刻,犬,きろく,記録した人\r\n2026/11/16,7:50,\"おはぎ, 2さい\",おしっこ,\r\n2026/11/16,7:52,\"おはぎ, 2さい\",うんち,パパ\r\n")
    }

    func testDailyText() {
        let a = Dog(name: "おはぎ", avatar: .ohagi, order: 0)
        let b = Dog(name: "きなこ", avatar: .kinako, order: 1)
        let t = Date(timeIntervalSince1970: 1_794_783_000) // 2026-11-16 (Mon) 07:50 JST
        let events = [
            WalkEvent(dogID: b.id, kind: .pee, date: t),
            WalkEvent(dogID: a.id, kind: .pee, date: t),
            WalkEvent(dogID: a.id, kind: .pee, date: t.addingTimeInterval(3600 * 5)),
            WalkEvent(dogID: a.id, kind: .poop, date: t.addingTimeInterval(60)),
        ]
        let text = Export.dailyText(dogs: [b, a].reversed(), events: events, timeZone: tokyo)
        XCTAssertEqual(text, "2026/11/16（月）\nおはぎ　おしっこ 2回（7:50, 12:50）・うんち 1回（7:51）\nきなこ　おしっこ 1回（7:50）\n")
    }
}
