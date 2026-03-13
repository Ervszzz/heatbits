import SwiftUI

struct ConfettiView: View {
    let accentColor: Color
    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .allowsHitTesting(false)
        .onAppear { burst() }
    }

    private func burst() {
        let colors: [Color] = [accentColor, .white, .yellow, accentColor.opacity(0.6), .white]
        pieces = (0..<60).map { i in
            ConfettiPiece(
                id: i,
                color: colors[i % colors.count],
                startX: CGFloat.random(in: 0.2...0.8),
                endX: CGFloat.random(in: 0...1),
                endY: CGFloat.random(in: 0.6...1.2),
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.3)
            )
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let startX: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var x: CGFloat = 0
    @State private var y: CGFloat = -0.05
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(piece.color)
                .frame(width: piece.size, height: piece.size * 0.6)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .position(
                    x: x * geo.size.width,
                    y: y * geo.size.height
                )
                .onAppear {
                    x = piece.startX
                    y = -0.05
                    withAnimation(.easeOut(duration: 1.2).delay(piece.delay)) {
                        x = piece.endX
                        y = piece.endY
                        rotation = piece.rotation + Double.random(in: 180...540)
                    }
                    withAnimation(.linear(duration: 0.5).delay(piece.delay + 0.8)) {
                        opacity = 0
                    }
                }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView(accentColor: Color(hex: "#30D158")!)
    }
}
