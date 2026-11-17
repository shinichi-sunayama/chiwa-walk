import SwiftUI
import WalkCore
#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

/// Colors and fonts shared by the iPhone and Watch apps (the workshop's cream / sky palette).
enum Theme {
    static let sky = Color(hex: 0xCFE9F7)
    static let sky2 = Color(hex: 0xE8F4E6)
    static let cream = Color(hex: 0xFBF3E4)
    static let card = Color(hex: 0xFFFDF8)
    static let lip = Color(hex: 0xE6D8BF)
    static let text = Color(hex: 0x4A3426)
    static let muted = Color(hex: 0x8A7562)
    static let orange = Color(hex: 0xF39A4C)
    static let orangeLip = Color(hex: 0xC8702A)
    static let green = Color(hex: 0x4F9E45)
    static let greenLip = Color(hex: 0x357530)
    static let red = Color(hex: 0xE2654F)
    static let chip = Color(hex: 0xF2E9D8)

    /// Rounded Japanese font bundled with the app (M PLUS Rounded 1c Bold, SIL OFL 1.1).
    static let fontName = "RoundedMplus1c-Bold" // PostScript name inside MPLUSRounded1c-Bold.ttf

    static func font(_ size: CGFloat) -> Font {
        .custom(fontName, size: size)
    }

    static var background: LinearGradient {
        LinearGradient(stops: [
            .init(color: sky, location: 0),
            .init(color: sky2, location: 0.2),
            .init(color: cream, location: 0.45),
        ], startPoint: .top, endPoint: .bottom)
    }
}

/// Look of each kind of record. Strong colors so the buttons are easy to tell apart outdoors.
extension EventKind {
    var emoji: String {
        switch self {
        case .pee: return "🟡" // quiet marks in the button colours (no 💩 on screen)
        case .poop: return "🟤"
        case .water: return "💧"
        case .food: return "🍽️"
        case .walkStart: return "🐾"
        case .walkEnd: return "🏠"
        }
    }

    var fill: Color {
        switch self {
        case .pee: return Color(hex: 0xF2C230)
        case .poop: return Color(hex: 0xA8754A)
        case .water: return Color(hex: 0x4FA3E0)
        case .food: return Color(hex: 0xF39A4C)
        case .walkStart, .walkEnd: return Color(hex: 0x4F9E45)
        }
    }

    var lip: Color {
        switch self {
        case .pee: return Color(hex: 0xC09412)
        case .poop: return Color(hex: 0x7A5230)
        case .water: return Color(hex: 0x2F78B0)
        case .food: return Color(hex: 0xC8702A)
        case .walkStart, .walkEnd: return Color(hex: 0x357530)
        }
    }

    /// Text color on the button (dark on yellow for contrast).
    var ink: Color {
        self == .pee ? Color(hex: 0x4A3426) : .white
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

/// The picture on a record button: the workshop's illustration (assets/kinds/<kind>.png or .svg, drawn with Gemini)
/// on a white circle (so a yellow drop stays visible on the yellow button), otherwise the emoji.
struct KindIcon: View {
    var kind: EventKind
    var size: CGFloat

    var body: some View {
        if let image = UIImage(named: "kind_\(kind.rawValue)") {
            Image(uiImage: image).resizable().scaledToFit()
                .frame(width: size * 1.05, height: size * 1.05)
                .frame(width: size * 1.5, height: size * 1.5)
                .background(Circle().fill(.white))
        } else {
            Text(kind.emoji).font(.system(size: size))
        }
    }
}

/// Raised button with a darker "lip" under it, pressed down when tapped.
struct LipButtonStyle: ButtonStyle {
    var fill: Color
    var lip: Color
    var corner: CGFloat = 18
    var depth: CGFloat = 5
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0)],
                                                 startPoint: .top, endPoint: .center))
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(lip)
                    .offset(y: pressed ? 1 : depth)
            )
            .offset(y: pressed ? depth - 1 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

/// Round dog picture: the user's own photo if set, otherwise one of the workshop's five dogs or a paw print.
struct DogFace: View {
    var avatar: Avatar
    var photo: Data? = nil
    var size: CGFloat
    var selected: Bool = true

    init(avatar: Avatar, photo: Data? = nil, size: CGFloat, selected: Bool = true) {
        self.avatar = avatar
        self.photo = photo
        self.size = size
        self.selected = selected
    }

    init(dog: Dog, size: CGFloat, selected: Bool = true) {
        self.init(avatar: dog.avatar, photo: dog.photo, size: size, selected: selected)
    }

    var body: some View {
        ZStack {
            Circle().fill(selected ? Theme.card : Theme.chip)
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let name = avatar.imageName {
                Image(name).resizable().scaledToFit().padding(size * 0.06)
            } else {
                Image(systemName: "pawprint.fill")
                    .resizable().scaledToFit().padding(size * 0.24)
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(selected ? Theme.orange : Theme.lip, lineWidth: selected ? max(2, size * 0.06) : 1))
        .opacity(selected ? 1 : 0.55)
    }
}
