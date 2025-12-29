# Japa Counter

A premium, minimalist digital counter designed for spiritual practices. Built with Flutter, this app offers a serene, environment for chanting mantras with advanced haptic feedback and OLED-friendly visuals.

##  Features

###  Core Functionality

- **Dual Modes**:
  - **Tactile Mode**: A physical-feeling button interface for precise counting.
  - **Focus Mode**: Tap anywhere on the screen to count (perfect for eyes-closed practice).
- **Mantra Management**: Create, Edit, rename, and delete multiple mantras with individual tracking.
- **Goal System**: Set custom goals (e.g., 108) and track "Malas" (rounds) completed.
- **History Tracking**: View your daily practice history and lifetime count stats.

### Visual & Experience

- **Zen Minimalist Design**: Dark-themed UI optimized for OLED screens to save battery and reduce eye strain.
- **Immersive Feedback**:
  - **Ripple Animations**: soothing visual ripples on every count.
  - **Haptics**: Subtle vibrations (light impact) for counts, distinct feedback for completing a Mala.
  - **Sound Effects**: Optional soft click sounds (wooden block style).
- **Zen Mode**: Toggle to hide all UI elements (status bars, buttons) for pure focus.

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Persistence**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Audio**: [AudioPlayers](https://pub.dev/packages/audioplayers)
- **Typography**: [Google Fonts](https://pub.dev/packages/google_fonts) (Outfit)
- **Icons**: [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)

## Getting Started

### Prerequisites

- Flutter SDK (>=3.2.0)
- Android/iOS Emulator or Physical Device

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Sujaykatmania/Japa-Counter.git
   cd Japa-Counter
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Screenshots

> _Add screenshots of Home Screen, Mantra Selector, and Settings here._

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
