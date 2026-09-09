//
//  CarouselItemModel.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 03/09/26.
//

import Foundation

struct CarouselItem: Identifiable, Codable {
    let image: String
    let title: String
    let description: String
    
    var id: String { image }
    
    enum CodingKeys: String, CodingKey {
        case image, title, description
    }
}

func carregarTutorial() -> [CarouselItem] {
    guard let url = Bundle.main.url(forResource: "Tutorial", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let itens = try? JSONDecoder().decode([CarouselItem].self, from: data) else {
        return []
    }
    return itens
}
