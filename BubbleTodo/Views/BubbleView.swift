//
//  BubbleView.swift
//  BubbleTodo
//

import SwiftUI

struct BubbleView: View {
    let task: TaskItem
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPopping = false
    @State private var bobOffset: CGFloat = 0

    // Calculate bubble diameter based on task's bubble size
    private var diameter: CGFloat {
        let baseSize: CGFloat = 60
        let scaleFactor: CGFloat = 15
        let size = baseSize + CGFloat(task.bubbleSize) * scaleFactor
        return min(max(size, 60), 180) // Clamp between 60-180
    }

    private var bubbleColor: Color {
        switch task.priority {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .orange
        }
    }

    var body: some View {
        ZStack {
            // Bubble background
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            bubbleColor.opacity(0.7),
                            bubbleColor
                        ]),
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: diameter / 2
                    )
                )
                .frame(width: diameter, height: diameter)
                .shadow(color: bubbleColor.opacity(0.4), radius: 8, x: 0, y: 4)

            // Highlight/shine effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.6),
                            .clear
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: diameter / 3
                    )
                )
                .frame(width: diameter * 0.4, height: diameter * 0.4)
                .offset(x: -diameter * 0.2, y: -diameter * 0.2)

            // Task title
            Text(task.title)
                .font(.system(size: min(diameter / 5, 16), weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(8)
                .frame(width: diameter - 16)
        }
        .offset(y: bobOffset)
        .scaleEffect(isPopping ? 1.3 : 1.0)
        .opacity(isPopping ? 0 : 1)
        .onAppear {
            startBobbing()
        }
        .onTapGesture {
            pop()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onLongPress()
        }
    }

    private func startBobbing() {
        let randomDelay = Double.random(in: 0...1)
        let randomDuration = Double.random(in: 1.5...2.5)

        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
            withAnimation(
                Animation
                    .easeInOut(duration: randomDuration)
                    .repeatForever(autoreverses: true)
            ) {
                bobOffset = CGFloat.random(in: -8...8)
            }
        }
    }

    private func pop() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.easeOut(duration: 0.3)) {
            isPopping = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onTap()
        }
    }
}

#Preview {
    let task = TaskItem(title: "Test Task", priority: 3)
    return BubbleView(task: task, onTap: {}, onLongPress: {})
        .padding()
}
