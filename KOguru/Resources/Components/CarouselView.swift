//
//  CarouselView.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 03/09/26.
//

import SwiftUI

struct CarouselView: View {
    
    let carouselItems = [
        CarouselItem(image: "car1", title: "Car 1"),
        CarouselItem(image: "car2", title: "Car 2"),
        CarouselItem(image: "car3", title: "Car 3"),
        CarouselItem(image: "car4", title: "Car 4")
    ]
    var body: some View {
        TabView {
            ForEach(carouselItems) { item in
                VStack {
                    // TODO: ajustar para que a imagem sempre esteja dentro de um tamanho aceitável
                    Image(item.image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    
                    Spacer()
                    
                    Text("lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                }
                .padding()
            }
        }
        .tabViewStyle(.page)
        .frame(height: 300)
    }
}

#Preview {
    CarouselView()
}
