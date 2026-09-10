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
                // MARK: - CABEÇALHO
                HStack {
                    if onStart == nil {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44, alignment: .leading)
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }
                    
                    Spacer()
                    
                    Text("INSTRUÇÕES")
                        .font(.custom("Anton", size: 24))
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // MARK: - CONTEÚDO
                ScrollView {
                    VStack(spacing: 0) {
                        Text("SOBRE O TREINO")
                            .font(.custom("Anton", size: 22))
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
                            .font(.custom("Anton", size: 22))
                            .foregroundColor(.white)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack {
                            CarouselView()
                        }
                        
                        Text("ANTES DE INICIAR, LEMBRE-SE:")
                            .font(.custom("Anton", size: 22))
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
                Button(action: {
                    if let onStart = onStart {
                        onStart()
                    } else {
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: onStart != nil ? "figure.boxing" : "xmark.circle")
                            .font(.system(size: 24))
                        
                        Text(onStart != nil ? "CONTINUAR PARA EXERCÍCIO" : "FECHAR INSTRUÇÕES")
                            .font(Font.custom("Anton", size: 24))
                            .fontWeight(.bold)
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.65, green: 0.15, blue: 0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityLabel("Continuar para exercício")
                .accessibilityHint("Toque duas vezes para fechar o tutorial e iniciar a câmera")
            }
            .padding(.horizontal, 17)
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("INSTRUÇÕES")
                    .font(.custom("Anton", size: 24))
                    .foregroundColor(.white)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
                .accessibilityLabel("Voltar")
                .accessibilityHint("Retorna à tela anterior")
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
        .navigationBarHidden(true)
    }
}
