//
//  CarouselItemModel.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 03/09/26.
//

import Foundation

struct CarouselItem: Identifiable {
    let id = UUID()
    let image: String
    let title: String
}
