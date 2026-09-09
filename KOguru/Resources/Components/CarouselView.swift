//
//  CarouselView.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 03/09/26.
//

import SwiftUI

struct CarouselView: View {
    
    let carouselItems = [
        CarouselItem(image: "car1", title: "PRIMEIRO PASSO", description: "Estenda o braço da frente rapidamente, girando levemente o punho no final do movimento. Mantenha a outra mão protegendo o rosto e retorne à guarda logo após o golpe."),
        CarouselItem(image: "car2", title: "SEGUNDO PASSO", description: "blabla"),
        CarouselItem(image: "car3", title: "TERCEIRO PASSO", description: "sjehfkshd"),
        CarouselItem(image: "car4", title: "QUARTO PASSO", description: "asihdoaeijdaol")
    ]
    var body: some View {
        TabView {
            ForEach(carouselItems) { item in
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title)
                            .font(.custom("SedgwickAveDisplay-Regular", size: 24))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 33)
                            .background(Color(red: 0.55, green: 0.14, blue: 0.15))
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 16
                                )
                            )
                        Image(item.image)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .frame(width: 370, height: 200)
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 16,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 16
                                )
                            )
                            .shadow(radius: 5)
                            .padding(.bottom, 10)
                        
                        Text(item.description)
                            .foregroundColor(.white)
                            .font(.system(size: 19))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 30)
                    }
                }
            }
        }
        .tabViewStyle(.page)
        .frame(height: 400)
    }
}

#Preview {
    CarouselView()
}
