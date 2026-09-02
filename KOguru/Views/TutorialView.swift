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
            Rectangle()
                .fill(Color.red)
                .frame(width: 286, height: 239)
                .cornerRadius(15)
            
            Text("Hello, world!")
            
            Spacer()
            
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


#Preview{
    NavigationStack{
        TutorialView()
    }
}
