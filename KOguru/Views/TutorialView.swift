//
//  TutorialView.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 01/09/26.
//

import SwiftUI

struct TutorialView: View {
    
    @State private var isPlaying: Bool = true
    
    var body: some View {
        VStack {
            
            Text("SOBRE O TREINO")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("lorem ipsum dolor sit amet, consectetur adipiscing elit.")
            
            Text("TUTORIAL")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack{
                CarouselView()
            }
            
            Spacer()
            // TODO: tem que fazer o botão ficar acima de qualquer bloco que esteja por trás
            
            Button(action: {
                print("apertou botao ")
            }) {
                Text("CONTINUAR PARA EXERCÍCIO")
                    .font(.title2)
                    .fontWeight(.bold)
                    .tracking(0.5)
                    .foregroundColor(.white)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.65, green: 0.15, blue: 0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("TUTORIAL")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.isPlaying.toggle()
                }) {
                    Image(systemName: self.isPlaying == true ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
            }
        }
        
    }
}

struct SquareLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 8) {
            configuration.icon
                .font(.title)
            configuration.title
                .font(.caption)
        }
        .frame(width: 90, height: 90) // Hardcoded 1:1 square frame
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


#Preview{
    NavigationStack{
        TutorialView()
    }
}
