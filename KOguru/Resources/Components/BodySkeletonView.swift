import SwiftUI

struct BodySkeletonView: View {
    var joints: [BodyJoint]
    var lineColor: Color = Color(red: 1.0, green: 0.78, blue: 0.0) // Amarelo #FFC700
    var lineWidth: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            let screenSize = geometry.size
            let imageAspectRatio: CGFloat = 9.0 / 16.0
            let screenAspectRatio = screenSize.width / screenSize.height
            
            let scaleW: CGFloat = screenAspectRatio > imageAspectRatio ? screenSize.width : screenSize.height * imageAspectRatio
            let scaleH: CGFloat = screenAspectRatio > imageAspectRatio ? screenSize.width / imageAspectRatio : screenSize.height
            
            let offsetX = (screenSize.width - scaleW) / 2
            let offsetY = (screenSize.height - scaleH) / 2

            let jointDict = Dictionary(uniqueKeysWithValues: joints.map { joint in
                let px = joint.position.x * scaleW + offsetX
                let py = joint.position.y * scaleH + offsetY
                return (joint.name, CGPoint(x: px, y: py))
            })

            ZStack {
                Path { path in
                    // Cabeça e Tronco Central (Pescoço ao centro dos quadris)
                    // (Vision não tem um ponto central para os quadris, então conectamos aos ombros)
                    drawLine(from: "NK", to: "LS", in: jointDict, path: &path)
                    drawLine(from: "NK", to: "RS", in: jointDict, path: &path)
                    
                    // Ombros e Tronco
                    drawLine(from: "LS", to: "RS", in: jointDict, path: &path)
                    drawLine(from: "LS", to: "LH", in: jointDict, path: &path) // Ombro Esq -> Quadril Esq
                    drawLine(from: "RS", to: "RH", in: jointDict, path: &path) // Ombro Dir -> Quadril Dir
                    drawLine(from: "LH", to: "RH", in: jointDict, path: &path) // Quadril a Quadril
                    
                    // Braços
                    drawLine(from: "LS", to: "LE", in: jointDict, path: &path)
                    drawLine(from: "LE", to: "LW", in: jointDict, path: &path)
                    drawLine(from: "RS", to: "RE", in: jointDict, path: &path)
                    drawLine(from: "RE", to: "RW", in: jointDict, path: &path)
                    
                    // Pernas
                    drawLine(from: "LH", to: "LK", in: jointDict, path: &path) // Quadril -> Joelho Esq
                    drawLine(from: "LK", to: "LA", in: jointDict, path: &path) // Joelho -> Tornozelo Esq
                    drawLine(from: "RH", to: "RK", in: jointDict, path: &path) // Quadril -> Joelho Dir
                    drawLine(from: "RK", to: "RA", in: jointDict, path: &path) // Joelho -> Tornozelo Dir
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .shadow(color: lineColor.opacity(0.6), radius: 6)
            }
        }
        .ignoresSafeArea()
    }

    private func drawLine(from startKey: String, to endKey: String, in dict: [String: CGPoint], path: inout Path) {
        if let start = dict[startKey], let end = dict[endKey] {
            path.move(to: start)
            path.addLine(to: end)
        }
    }
}
