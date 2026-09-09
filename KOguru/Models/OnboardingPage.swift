//
//  OnboardingPage.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 09/09/26.
//

import Foundation

struct OnboardingPage: Identifiable, Hashable {
    enum ActionStyle: Hashable {
        case arrow
        case title(String)
    }

    let id: Int
    let imageName: String
    let title: String
    let paragraphs: [String]
    let actionStyle: ActionStyle
}
