import SwiftUI

enum WDS {
    static let bgBase = Color(red: 255/255, green: 251/255, blue: 240/255)
    static let fgStrong = Color(red: 50/255, green: 46/255, blue: 38/255)
    static let fgPale = Color(red: 195/255, green: 186/255, blue: 167/255)
    static let fgNeutral = Color(red: 108/255, green: 101/255, blue: 87/255)

    static func font(_ size: CGFloat) -> Font {
        .custom("Ownglyph_PDH-Rg", size: size + 1)
    }
}
