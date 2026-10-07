//
//  WarmUpCard.swift
//  KOguru
//
//  Created by Bernardo on 06/10/26.
//

import SwiftUI

struct WarmUpCard: View {
    var body: some View {
        TrainCard(
            color: .amareloCard,
            titulo: "AQUECIMENTO",
            subTitulo: "Previna lesões antes do round",
            ImagemBack: "explozaoAmarelo"
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    WarmUpCard()
}