//
//  PhraseViewModel.swift
//  KOguru
//
//  Created by Letícia Marreiro Lopes Silva on 08/09/26.
//

import Foundation
import SwiftUI
import Combine

struct Phrase: Codable, Identifiable {
    let id: Int
    let text: String
}

class PhraseViewModel: ObservableObject {
    @Published var phrases: [Phrase] = []
    @Published var currentImage: String = "card-sorriso"
    @Published var currentPhrase: Phrase?
    
    let cardBackground = ["card-cansado", "card-maroto", "card-sorriso", "card-guarda"]
    
    init() {
        loadPhrase()
        nextPhrase()
    }
    
    func loadPhrase(){
        guard let url = Bundle.main.url(forResource: "Phrases", withExtension: "json") else {
            print("Arquivo Phrases.json não encontrado.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            
            self.phrases = try decoder.decode([Phrase].self, from: data)
        } catch {
            print("Erro ao decodificar o json: \(error)")
        }
    }
    
    func nextPhrase(){
        guard !phrases.isEmpty else { return }
        currentPhrase = phrases.randomElement()
        currentImage = cardBackground.randomElement() ?? "card-sorriso"
    }
}
