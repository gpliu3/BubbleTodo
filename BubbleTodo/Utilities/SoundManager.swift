//
//  SoundManager.swift
//  BubbleTodo
//

import AVFoundation
import AudioToolbox
import UIKit

enum SoundManager {
    /// Configure audio session to allow sounds even in silent mode
    private static func configureAudioSession() {
        do {
            // Use .playback with .mixWithOthers to play sounds even in silent mode
            // while still allowing other audio to play
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Silently fail if audio session can't be configured
        }
    }

    /// Play sound when popping a bubble
    static func playPopSound() {
        configureAudioSession()
        // Use system pop sound (like when you pop a notification)
        AudioServicesPlaySystemSound(1306) // Peek sound - very satisfying pop
    }

    /// Play sound when adding a new task
    static func playAddTaskSound() {
        configureAudioSession()
        // Use system success sound
        AudioServicesPlaySystemSound(1054) // New mail sound - gentle chime
    }

    /// Play haptic feedback with sound
    static func playPopWithHaptic() {
        configureAudioSession()

        // Strong vibration for satisfying pop feeling
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        // Play a satisfying pop sound
        AudioServicesPlaySystemSound(1519) // Actuate sound - clean pop

        // Optional: Add system vibration for older devices
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    /// Play success sound with haptic
    static func playSuccessWithHaptic() {
        configureAudioSession()

        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)

        // Play success chime
        AudioServicesPlaySystemSound(1025) // SMS received tone - satisfying
    }
}
