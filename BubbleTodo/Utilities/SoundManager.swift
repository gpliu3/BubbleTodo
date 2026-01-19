//
//  SoundManager.swift
//  BubbleTodo
//

import AVFoundation
import AudioToolbox
import UIKit

enum SoundManager {
    private static var popPlayer: AVAudioPlayer?
    private static var successPlayer: AVAudioPlayer?

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

        // Use AVAudioPlayer for louder sound
        if let soundURL = Bundle.main.url(forResource: "Tock", withExtension: "aiff", subdirectory: "SystemSounds") ??
                          URL(string: "/System/Library/Audio/UISounds/Tock.aiff") {
            do {
                successPlayer = try AVAudioPlayer(contentsOf: soundURL)
                successPlayer?.volume = 1.0  // Maximum volume
                successPlayer?.play()
            } catch {
                // Fallback to system sound
                AudioServicesPlaySystemSound(1054)
            }
        } else {
            AudioServicesPlaySystemSound(1054)
        }
    }

    /// Play haptic feedback with sound
    static func playPopWithHaptic() {
        configureAudioSession()

        // Use AVAudioPlayer for MUCH louder sound
        if let soundURL = URL(string: "/System/Library/Audio/UISounds/nano/3rdParty_Success_Haptic.caf") {
            do {
                popPlayer = try AVAudioPlayer(contentsOf: soundURL)
                popPlayer?.volume = 1.0  // Maximum volume
                popPlayer?.play()
            } catch {
                // Fallback to system sound
                AudioServicesPlaySystemSound(1104)
            }
        } else {
            AudioServicesPlaySystemSound(1104)
        }

        // Haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }

    /// Play success sound with haptic
    static func playSuccessWithHaptic() {
        configureAudioSession()

        // Use AVAudioPlayer for louder sound
        if let soundURL = URL(string: "/System/Library/Audio/UISounds/new-mail.caf") {
            do {
                successPlayer = try AVAudioPlayer(contentsOf: soundURL)
                successPlayer?.volume = 1.0  // Maximum volume
                successPlayer?.play()
            } catch {
                AudioServicesPlaySystemSound(1025)
            }
        } else {
            AudioServicesPlaySystemSound(1025)
        }

        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
}
