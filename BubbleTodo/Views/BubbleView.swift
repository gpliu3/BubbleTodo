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

    // Pre-computed values for better performance
    private let diameter: CGFloat
    private let bubbleColor: Color

    // Shared haptic feedback generator (prepared once)
    private static let longPressHaptic: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()

    init(task: TaskItem, onTap: @escaping () -> Void, onLongPress: @escaping () -> Void) {
        self.task = task
        self.onTap = onTap
        self.onLongPress = onLongPress

        // Pre-compute diameter
        let baseSize: CGFloat = 50
        let scaleFactor: CGFloat = 11.5
        let size = baseSize + CGFloat(task.bubbleSize) * scaleFactor
        self.diameter = min(max(size, 60), 180)

        // Pre-compute color
        switch task.priority {
        case 1: self.bubbleColor = .green
        case 2: self.bubbleColor = .yellow
        case 3: self.bubbleColor = .orange
        case 4: self.bubbleColor = .red
        case 5: self.bubbleColor = .purple
        default: self.bubbleColor = .orange
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

            // Content: Title and time
            VStack(spacing: 2) {
                // Task title - scales with bubble size
                Text(task.title)
                    .font(.system(size: min(diameter / 4.5, 24), weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: diameter - 20)

                // Time label - fixed size
                Text(task.effortLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.2))
                    )
            }

            // Burst animation overlay when popping
            if isPopping {
                BubblePopAnimation(color: bubbleColor, diameter: diameter)
                    .allowsHitTesting(false)
            }
        }
        .offset(y: bobOffset)
        .scaleEffect(isPopping ? 1.2 : 1.0)
        .opacity(isPopping ? 0 : 1)
        .onAppear {
            startBobbing()
        }
        .onTapGesture {
            pop()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            Self.longPressHaptic.impactOccurred()
            Self.longPressHaptic.prepare() // Prepare for next use
            onLongPress()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: L("accessibility.bubble"), task.title, task.priorityLabel, task.effortLabel))
        .accessibilityHint(L("accessibility.bubble.hint"))
        .accessibilityAddTraits(.isButton)
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
        // Play satisfying pop sound with haptic
        SoundManager.playPopWithHaptic()

        withAnimation(.spring(response: 0.9, dampingFraction: 0.6)) {
            isPopping = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onTap()
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.systemGray6)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        HStack(spacing: 30) {
            BubbleView(task: TaskItem(title: "Quick", priority: 1, effort: 1), onTap: {}, onLongPress: {})
            BubbleView(task: TaskItem(title: "Medium task", priority: 3, effort: 30), onTap: {}, onLongPress: {})
            BubbleView(task: TaskItem(title: "Big project", priority: 5, effort: 120), onTap: {}, onLongPress: {})
        }
    }
}
