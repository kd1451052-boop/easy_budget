# Gamification Implementation Notes

These notes outline the step-by-step technical implementation for adding gamification (Streaks, Badges, and Visual Celebrations) to Easy Budget.

## 1. Data Layer: Gamification Provider
We need a central place to store user progress.
- Create `lib/gamification_provider.dart` using `ChangeNotifier`.
- Manage state for **Streaks**:
  - `int currentStreak`
  - `DateTime? lastActiveDate`
  - Logic to increment the streak if the app is opened on consecutive days, and reset it if a day is missed.
- Manage state for **Achievements/Badges**:
  - Create a list of `Achievement` models (e.g., "First Expense", "Receipt Master", "7-Day Streak").
  - Methods to check and unlock achievements based on user actions.
- Save everything persistently using `SharedPreferences`.

## 2. Feature 1: Streaks
- **`lib/home_page.dart`**: Update the UI to display the current streak (e.g., "🔥 5 Day Streak") prominently at the top of the dashboard. Keep the style simple for now (future enhancements will add more animations).
- **`lib/main.dart`**: Initialize `GamificationProvider` alongside other providers. Trigger the "app opened" event to update the streak logic daily.

## 3. Feature 2: Milestone Badges & Achievements
- **`lib/achievements_page.dart`**: Create a detailed screen listing all achievements. 
  - Unlocked badges are vibrant and show the unlocked reward (e.g., special avatar frame/profile picture).
  - Locked badges are greyed out but show the condition to unlock and the current progress (e.g., 2/10 receipts scanned).
- **`lib/settings_page.dart`**: Add a navigation button/ListTile in the Settings or Profile area to open the new `AchievementsPage`.
- **`lib/scanner.dart` & `lib/add_transaction_screen.dart`**: Add logic to notify the `GamificationProvider` whenever a receipt is scanned or an expense is added, so badges can unlock in real-time.

## 4. Feature 3: Visual Goals, Confetti, and Sound
- **`pubspec.yaml`**: Add the `confetti: ^0.8.0` and `audioplayers` dependencies.
- **`lib/main_navigation_screen.dart` (or `home_page.dart`)**: Wrap the main scaffold with a `ConfettiWidget` overlay. 
- Listen to the `GamificationProvider`. Whenever a new badge is unlocked or a major milestone is reached, fire the confetti animation across the screen AND play a sound effect.

## 5. Feature 4: Quick Actions
- Add the `quick_actions` package.
- In `main.dart`, register a home screen quick action ("Scan Receipt").
- When the action is triggered, navigate the user directly into the Scanner bottom sheet to streamline UX.
