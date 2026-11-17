import Foundation

/// Which dogs a one-tap button records for. Shared by the iPhone and the Watch so both behave the same:
/// - tap a dog = switch to that dog only (the common case; avoids recording for a dog by mistake)
/// - 「みんな」 = every dog
/// - long press (iPhone) / the check list (Watch) = add or remove one dog
public enum DogSelection {
    public static func only(_ id: UUID) -> Set<UUID> { [id] }

    public static func all(_ dogs: [Dog]) -> Set<UUID> { Set(dogs.map(\.id)) }

    public static func toggled(_ id: UUID, in selected: Set<UUID>) -> Set<UUID> {
        var s = selected
        if s.contains(id) { s.remove(id) } else { s.insert(id) }
        return s
    }

    public static func isAll(_ selected: Set<UUID>, dogs: [Dog]) -> Bool {
        !dogs.isEmpty && Set(dogs.map(\.id)).isSubset(of: selected)
    }

    /// After a dog is added: keep the current choice (so records don't silently go to the new dog too);
    /// pick the new dog only when nothing is selected.
    public static func afterAdding(_ id: UUID, to selected: Set<UUID>) -> Set<UUID> {
        selected.isEmpty ? [id] : selected
    }

    /// Drop dogs that no longer exist. If that leaves nothing but dogs exist, pick the first dog.
    public static func cleaned(_ selected: Set<UUID>, dogs: [Dog]) -> Set<UUID> {
        let valid = selected.intersection(dogs.map(\.id))
        if valid.isEmpty, let first = dogs.sorted(by: { $0.order < $1.order }).first { return [first.id] }
        return valid
    }

    /// Names of the selected dogs in order: 「おはぎ」「おはぎ・きなこ」「みんな（3びき）」.
    public static func label(_ selected: Set<UUID>, dogs: [Dog]) -> String {
        let chosen = dogs.sorted { $0.order < $1.order }.filter { selected.contains($0.id) }
        if chosen.isEmpty { return "" }
        if chosen.count >= 3 && chosen.count == dogs.count { return "みんな（\(chosen.count)びき）" }
        if chosen.count >= 3 { return "\(chosen[0].name)・\(chosen[1].name) ほか\(chosen.count - 2)" }
        return chosen.map(\.name).joined(separator: "・")
    }
}
