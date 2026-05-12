//
//  MemorTheme.swift
//  memor
//
//  Created by 0xrpheus on 11/5/26.
//

import SwiftUI

/// Central design token registry for memor.
/// All views pull from here — no hex literals scattered around.
enum MemorTheme {

    // MARK: - Colors

    /// #F8F5F0 — primary background
    static let cream      = Color(red: 0.973, green: 0.961, blue: 0.941)

    /// #EDE8E0 — tab bar, stat cards, secondary surfaces
    static let creamDark  = Color(red: 0.929, green: 0.910, blue: 0.878)

    /// #E3DDD5 — progress bar background
    static let creamDeeper = Color(red: 0.890, green: 0.867, blue: 0.835)

    /// #1A1714 — primary text, buttons
    static let ink        = Color(red: 0.102, green: 0.090, blue: 0.078)

    /// #4A4540 — secondary text
    static let inkMid     = Color(red: 0.290, green: 0.271, blue: 0.251)

    /// #8C8680 — tertiary / labels
    static let inkSoft    = Color(red: 0.549, green: 0.525, blue: 0.502)

    /// #D94B2B — coral-red accent pulled from the app icon
    static let red        = Color(red: 0.851, green: 0.294, blue: 0.169)

    // MARK: - Typography

    /// Lora regular — track titles, wordmarks, stat numbers
    static func serif(size: CGFloat) -> Font {
        .custom("Lora-Regular", size: size)
    }

    /// Lora italic — track titles, wordmark on login
    static func serifItalic(size: CGFloat) -> Font {
        .custom("Lora-Italic", size: size)
    }

    /// Lora medium
    static func serifMedium(size: CGFloat) -> Font {
        .custom("Lora-Medium", size: size)
    }
}
