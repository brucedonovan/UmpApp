<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# UmpApp - Cricket Umpiring Application

This is an iOS application with Apple Watch support for cricket umpiring. The app allows umpires to track cricket game statistics including:

## Key Features
- Track overs and balls per over
- Record runs scored (0-6 and custom amounts)
- Handle cricket extras:
  - Wides
  - No balls
  - Byes
  - Leg byes
- Undo functionality for the last ball
- Game reset functionality
- Visual feedback for over completion
- Ball history tracking

## Architecture
- **Shared Model**: `CricketGameModel.swift` contains the core game logic and is shared between iOS and Watch apps
- **iOS App**: Full-featured interface optimized for iPhone/iPad
- **Watch App**: Simplified interface optimized for Apple Watch with tab-based navigation

## Technical Details
- Built with SwiftUI
- Uses `@ObservableObject` for state management
- Supports iOS 17.0+ and watchOS 10.0+
- Follows Apple's Human Interface Guidelines for both platforms

## Code Style Guidelines
- Use SwiftUI best practices
- Maintain separation between UI and business logic
- Keep Watch app interface simple and touch-friendly
- Use haptic feedback on Watch for user actions
- Follow Apple's accessibility guidelines
