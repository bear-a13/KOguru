import SwiftUI

struct TutorialView: View {
    var onStart: (() -> Void)? = nil
    
    @State private var isPlaying: Bool = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(Color.backgroundColorBlue)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            
            VStack(spacing: 0) {
                // MARK: - CABEÇALHO CUSTOMIZADO
                HStack {
                    Spacer()
                    
                    Text("INSTRUÇÕES")
                        .font(.custom("Anton", size: 30))
                        .foregroundColor(.white)
                        .bold()
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // MARK: - CONTEÚDO
                ScrollView {
                    VStack(spacing: 0) {
                        Text("SOBRE O TREINO")
                            .font(.custom("Anton", size: 26))
                            .foregroundColor(.white)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 9)
                        
                        Text("Você irá praticar os golpes jab e direto, trabalhando precisão e técnica. Seus golpes serão identificados e analisados.")
                            .foregroundStyle(.white)
                            .font(.system(size: 19))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 9)
                        
                        Text("TUTORIAL")
                            .font(.custom("Anton", size: 26))
                            .foregroundColor(.white)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack {
                            CarouselView()
                        }
                        
                        Text("ANTES DE INICIAR, LEMBRE-SE:")
                            .font(.custom("Anton", size: 26))
                            .foregroundColor(.white)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 9)
                        
                        VStack {
                            HStack {
                                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                    .foregroundColor(.white)
                                    .font(.system(size: 19))
                                Text("Mantenha o espaço livre ao seu redor e afaste-se de outras pessoas.")
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 19))
                            }
                            .padding(.bottom, 10)
                            
                            HStack {
                                Image(systemName: "person.fill.viewfinder")
                                    .foregroundColor(.white)
                                    .font(.system(size: 19))
                                Text("Treine sempre virado levemente para a direita.")
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 19))
                            }
                            .padding(.bottom, 10)
                            
                            HStack {
                                Image(systemName: "figure.boxing")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 19))
                                Text("Mantenha seu corpo inteiro visível para o reconhecimento correto dos movimentos.")
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 19))
                            }
                        }
                        
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 16)
            
            // MARK: - BOTÃO INFERIOR
            HStack(alignment: .center) {
                PrimaryActionButton(
                    title: onStart != nil ? "CONTINUAR PARA EXERCÍCIO" : "FECHAR INSTRUÇÕES",
                    systemImage: onStart != nil ? "figure.boxing" : "xmark.circle",
                    backgroundColor: Color(red: 0.65, green: 0.15, blue: 0.13),
                    accessibilityHint: onStart != nil
                        ? "Toque duas vezes para fechar o tutorial e iniciar a câmera"
                        : "Retorna ao exercício",
                    action: {
                        if let onStart = onStart {
                            onStart()
                        } else {
                            dismiss()
                        }
                    }
                )
            }
            .padding(.horizontal, 17)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
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
        .frame(width: 90, height: 90)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    TutorialView()
}
