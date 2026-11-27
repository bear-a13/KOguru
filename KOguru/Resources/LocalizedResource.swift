//
//  LocalizedResource.swift
//  KOguru
//

import Foundation

/// Selects the localized variant of a bundled JSON resource based on the
/// system language. The unqualified file is the base (pt-BR) version.
enum LocalizedResource {
    static func name(for base: String) -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "pt"
        guard languageCode != "pt" else { return base }
        return "\(base)-\(languageCode)"
    }
}
