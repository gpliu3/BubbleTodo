# BubbleTodo 🫧

A delightful iOS todo app where tasks float as interactive bubbles. Pop them to complete, watch them rise throughout the day, and keep your tasks organized with a playful, intuitive interface.

## ✨ Features

### 🎈 Bubble-Based Task Visualization
- **Dynamic Sizing**: Bubble size reflects task effort (1 min to 2 hours)
- **Smart Ordering**: Tasks arranged by priority and due time
- **Floating Animation**: Bubbles gently bob and rise as the day progresses
- **Satisfying Interactions**: Pop bubbles with delightful animations and haptic feedback

### 📅 Flexible Task Management
- **One-off Tasks**: Set specific deadlines with "Before" or "On" due date types
- **Recurring Tasks**: Daily, weekly, or monthly recurrence with optional specific times
- **Priority Levels**: 5 priority levels with color-coded indicators (Low to Critical)
- **Effort Tracking**: Time-based effort estimates (1min, 5min, 15min, 30min, 1hr, 2hr)

### 🔔 Smart Notifications
- **Customizable Reminders**: 1-4 daily reminders with custom times
- **Task Lists**: Notifications show actual task titles
- **Time-Sensitive**: Uses iOS time-sensitive notifications for important tasks

### 🎨 User Experience
- **Undo Support**: 3-second undo window after completing tasks
- **Sound & Haptics**: Satisfying audio and tactile feedback
- **Completed Tasks View**: Review your accomplishments with filtering options
- **Localization**: Full support for English and Simplified Chinese

### 🌓 Time-Based UI
- **Day Progress Indicator**: Background gradient changes from morning to evening
- **Rising Bubbles**: Tasks float higher as the day progresses (6 AM to 10 PM)
- **Visual Time Awareness**: Due time affects bubble positioning

## 📱 Requirements

- iOS 18.6 or later
- iPhone or iPad

## 🛠️ Tech Stack

- **Framework**: SwiftUI
- **Persistence**: SwiftData
- **Notifications**: UserNotifications (UNUserNotificationCenter)
- **Audio**: AVFoundation
- **Localization**: String Catalogs (English, Simplified Chinese)
- **Architecture**: MVVM with @Observable and Combine

## 🏗️ Project Structure

```
BubbleTodo/
├── Models/
│   └── TaskItem.swift          # Core task model with SwiftData
├── Views/
│   ├── MainBubbleView.swift    # Main bubble interface
│   ├── BubbleView.swift        # Individual bubble component
│   ├── BubblePopAnimation.swift # Pop animation effects
│   ├── AddTaskSheet.swift      # New task creation
│   ├── EditTaskSheet.swift     # Task editing
│   ├── CompletedTasksView.swift # Completed tasks history
│   └── SettingsView.swift      # App settings
├── Utilities/
│   ├── NotificationManager.swift # Notification scheduling
│   ├── SoundManager.swift       # Audio playback
│   └── LocalizationManager.swift # Language management
└── Resources/
    ├── Sounds/                  # Audio files
    └── Localizations/          # String catalogs
```

## 🎯 Key Algorithms

### Bubble Sizing
```swift
// Effort-based sizing with square root scaling
var bubbleSize: Double {
    sqrt(effort)
}

var diameter: CGFloat {
    let baseSize: CGFloat = 50
    let scaleFactor: CGFloat = 11.5
    let size = baseSize + CGFloat(bubbleSize) * scaleFactor
    return min(max(size, 60), 180)
}
```

### Task Sorting
Tasks are scored based on:
- **Priority**: 1000-5000 points (1000 per priority level)
- **Due Today**: Earlier times get higher scores (0-500 bonus)
- **Overdue**: Exponential urgency penalties
- **"Before" Type**: Urgency increases as deadline approaches
- **Age**: Slight boost for older tasks without due dates

### Task Visibility
- **One-off "On" type**: Shows only on the due date and when overdue
- **One-off "Before" type**: Shows from creation until end of due date day
- **Recurring**: Shows only on scheduled occurrence days
- **No due date**: Always visible

## 🚀 Getting Started

1. Clone the repository:
```bash
git clone https://github.com/yourusername/BubbleTodo.git
cd BubbleTodo
```

2. Open in Xcode:
```bash
open BubbleTodo.xcodeproj
```

3. Build and run on your device or simulator (iOS 18.6+)

## 🎮 Usage

### Creating Tasks
1. Tap the **+** button in the bottom-right corner
2. Enter task details:
   - **Title**: What needs to be done
   - **Priority**: Urgency level (1-5)
   - **Time needed**: Estimated effort
   - **One-off task**: Toggle ON for single tasks, OFF for recurring
   - For one-off: Set date/time and choose "Before" or "On" type
   - For recurring: Choose frequency and optionally set specific time

### Completing Tasks
- **Tap** a bubble to complete the task
- Watch the satisfying pop animation
- **Undo** within 3 seconds if needed

### Managing Completed Tasks
- Navigate to **Done** screen from tab bar
- Filter by: Today, This Week, This Month, or All Time
- **Long press** to edit completed tasks
- **Swipe left** to delete
- **Swipe right** to restore (if not past due)

### Settings
- **Notifications**: Enable and configure 1-4 daily reminders
- **Language**: Switch between English and Chinese
- **Permissions**: Manage notification access

## 🎨 Design Philosophy

BubbleTodo transforms the mundane task list into a playful, engaging experience:

- **Visual Metaphor**: Bubbles represent tasks floating to the surface of your attention
- **Size as Priority**: Bigger bubbles (longer tasks) naturally draw more attention
- **Time as Motion**: Bubbles rise throughout the day, creating urgency
- **Completion as Release**: Popping bubbles provides satisfying closure
- **Color as Signal**: Priority colors provide instant visual feedback

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with SwiftUI and SwiftData
- Developed with assistance from Claude Sonnet 4.5
- Inspired by the need for a more joyful task management experience

## 📧 Contact

For questions, suggestions, or feedback, please open an issue on GitHub.

---

Made with ❤️ and ☕
