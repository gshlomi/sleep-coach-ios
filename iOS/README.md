# Sleep Coach - iOS App Build Instructions

## Prerequisites

1. **macOS** with Xcode 15+ installed
2. **Node.js 20+** for the backend
3. **Apple Developer Account** (for device deployment)

## Quick Start

### 1. Backend Setup

```bash
# Navigate to backend directory
cd Backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Start the server
npm start
```

The backend will run at `http://localhost:3000`

### 2. iOS Setup

```bash
# Navigate to iOS directory
cd iOS

# Install XcodeGen if not already installed
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open in Xcode
open SleepCoach.xcodeproj
```

### 3. Build in Xcode

1. Select your target device or simulator (iPhone 15, etc.)
2. Press **Cmd+R** to build and run

## Project Generation

If you modify the project structure, regenerate the Xcode project:

```bash
cd iOS
xcodegen generate
```

## Configuration

### API URL Configuration

The app is configured to use different API URLs based on build environment:

- **Simulator**: `http://localhost:3000`
- **Device**: Requires running backend on accessible URL

To change the production API URL, edit:
`SleepCoach/Services/APIService.swift`

### HealthKit Entitlements

HealthKit requires proper provisioning. For simulator testing, HealthKit functionality won't work (no Health app).

For device testing:
1. Enable HealthKit capability in Xcode
2. Set your Development Team in Signing & Capabilities
3. The entitlements file will be automatically configured

## Troubleshooting

### "XcodeGen command not found"
```bash
brew install xcodegen
```

### "Build fails with missing modules"
1. Open `SleepCoach.xcodeproj` in Xcode
2. File → Packages → Reset Package Caches
3. Build again

### "HealthKit authorization fails"
- HealthKit requires a physical device
- Simulator doesn't support HealthKit
- Ensure the entitlement file is properly configured

### "Cannot connect to API"
1. Ensure backend is running: `curl http://localhost:3000/health`
2. Check the baseURL in APIService.swift
3. For physical device, use your computer's local IP address

## Architecture Overview

```
SleepCoach/
├── SleepCoachApp.swift      # App entry point
├── Models/                   # Data models
│   ├── SleepLog.swift
│   ├── UserPreferences.swift
│   └── SleepInsight.swift
├── Views/                    # SwiftUI views
│   ├── OnboardingView.swift
│   ├── DashboardView.swift
│   ├── SleepLogView.swift
│   ├── AnalyticsView.swift
│   └── InsightsView.swift
├── Services/                 # Business logic services
│   ├── APIService.swift
│   ├── NotificationManager.swift
│   ├── HealthKitManager.swift
│   └── StorageManager.swift
└── ViewModels/              # MVVM view models
    ├── SleepViewModel.swift
    └── InsightsViewModel.swift
```

## Key Features Implementation

### Offline-First
The app stores data locally and syncs with the backend when online. Check `StorageManager.swift` for local storage implementation.

### Notifications
Pre-sleep task reminders are managed by `NotificationManager.swift`. Notifications are scheduled daily based on the user's planned bedtime.

### HealthKit Integration
Sleep data can be imported from Apple Watch via `HealthKitManager.swift`.

### Bilingual Support
Full Hebrew and English support with RTL layout. String translations are in `Resources/en.lproj/` and `Resources/he.lproj/`.

## App Store Submission

See `../DEPLOY.md` for detailed App Store submission instructions.

## License

MIT License - See parent README for details.
