# Sleep Coach iOS App 🌙

A comprehensive iOS app for tracking sleep patterns and improving sleep quality through personalized insights and pre-sleep task reminders.

## Features

### iOS App (Swift/SwiftUI)
- **Onboarding**: Set planned bedtime, wake time, sleep goals
- **Dashboard**: Today's sleep score, upcoming reminders, sleep streak
- **Sleep Logging**: 
  - Manual entry with bedtime, wake time, quality rating, notes
  - HealthKit integration (import sleep from Apple Watch)
- **Analytics**: Weekly/monthly sleep patterns, trends, charts
- **Insights**: AI-powered personalized recommendations
- **Bilingual**: Hebrew and English support
- **Dark Mode**: Full dark mode support

### Pre-Sleep Task Reminders
| Time Before Bed | Task | Description |
|----------------|------|-------------|
| 2 hours | Screen Shutdown | Stop using screens |
| 1 hour | Wind Down | Begin relaxing routine |
| 30 min | Worry List | Journal tomorrow's worries |
| 15 min | Breathing Exercise | 4-7-8 technique |
| 5 min | Cognitive Shuffle | Mental quieting technique |

## Project Structure

```
sleep-coach-ios/
├── iOS/
│   ├── SleepCoach/
│   │   ├── SleepCoachApp.swift      # App entry point
│   │   ├── Models/
│   │   │   ├── SleepLog.swift        # Sleep log model
│   │   │   ├── UserPreferences.swift # User preferences
│   │   │   └── SleepInsight.swift    # Insight models
│   │   ├── Views/
│   │   │   ├── OnboardingView.swift  # Onboarding flow
│   │   │   ├── DashboardView.swift   # Main dashboard
│   │   │   ├── SleepLogView.swift    # Sleep logging
│   │   │   ├── AnalyticsView.swift  # Charts & stats
│   │   │   └── InsightsView.swift   # AI recommendations
│   │   ├── Services/
│   │   │   ├── APIService.swift      # Backend API client
│   │   │   ├── NotificationManager.swift # Push notifications
│   │   │   ├── HealthKitManager.swift # HealthKit integration
│   │   │   └── StorageManager.swift  # Local storage
│   │   ├── ViewModels/
│   │   │   ├── SleepViewModel.swift  # Sleep data management
│   │   │   └── InsightsViewModel.swift # Insights management
│   │   └── Resources/
│   │       ├── Assets.xcassets       # App assets
│   │       ├── en.lproj/            # English strings
│   │       └── he.lproj/            # Hebrew strings
│   ├── project.yml                  # XcodeGen config
│   └── README.md                    # iOS build instructions
│
├── Backend/
│   ├── server.js                    # Express API server
│   ├── routes/                      # API endpoints
│   ├── services/                    # Business logic
│   └── storage/                     # SQLite database
│
└── API/
    └── openapi.yaml                 # API documentation
```

## Getting Started

### Prerequisites

- **iOS Development**: Xcode 15+, macOS Ventura+
- **Backend**: Node.js 20+, npm

### Backend Setup

```bash
cd Backend
npm install
cp .env.example .env  # Edit with your values
npm start
```

The API will be available at `http://localhost:3000`

### iOS Setup

1. **Install XcodeGen** (if not installed):
   ```bash
   brew install xcodegen
   ```

2. **Generate Xcode project**:
   ```bash
   cd iOS
   xcodegen generate
   ```

3. **Open in Xcode**:
   ```bash
   open SleepCoach.xcodeproj
   ```

4. **Configure signing**:
   - Select the SleepCoach target
   - Under "Signing & Capabilities", select your team
   - Enable HealthKit capability

5. **Build and run**:
   - Select an iOS 17+ simulator or device
   - Press Cmd+R to build and run

### Backend API

The backend must be running for full functionality. The app works offline with local storage and syncs when online.

**API Base URL**:
- Development: `http://localhost:3000`
- Production: `https://api.sleepcoach.app`

## API Endpoints

### Authentication
```
POST /api/users/register   - Create new user
POST /api/users/login      - Login user
GET  /api/users/profile    - Get user profile
PUT  /api/users/profile    - Update profile
```

### Sleep Logs
```
GET  /api/sleep/logs       - Get user's sleep logs
POST /api/sleep/logs       - Submit sleep log
GET  /api/sleep/logs/:id   - Get specific log
PUT  /api/sleep/logs/:id   - Update log
DELETE /api/sleep/logs/:id - Delete log
POST /api/sleep/tasks/complete - Record task completion
```

### Insights
```
GET /api/insights/summary        - Dashboard summary
GET /api/insights/weekly         - Weekly analysis
GET /api/insights/monthly        - Monthly analysis
GET /api/insights/recommendations - Personalized tips
```

## Architecture

### iOS App
- **Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI (iOS 17+)
- **Networking**: URLSession with async/await
- **Storage**: UserDefaults + JSON file storage
- **Health**: HealthKit framework

### Backend
- **Runtime**: Node.js 20+
- **Framework**: Express.js
- **Database**: SQLite (better-sqlite3)
- **Auth**: JWT tokens
- **Architecture**: REST API

## Configuration

### Environment Variables (Backend)

```env
PORT=3000
NODE_ENV=development
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d
DB_PATH=./storage/sleep_coach.db
```

### iOS API Configuration

Edit `APIService.swift` to configure the backend URL:

```swift
#if targetEnvironment(simulator)
self.baseURL = "http://localhost:3000"
#else
self.baseURL = "https://api.sleepcoach.app"
#endif
```

## Troubleshooting

### Build Errors
1. Ensure Xcode 15+ is installed
2. Run `xcodegen generate` in the iOS folder
3. Clean build folder (Cmd+Shift+K) and rebuild

### HealthKit Not Working
1. Ensure HealthKit capability is enabled in Xcode
2. Check that the device has Health app with sleep data
3. Verify simulator doesn't support HealthKit (use physical device)

### API Connection Issues
1. Ensure backend is running (`npm start` in Backend folder)
2. Check the baseURL in APIService.swift matches your backend
3. For physical devices, use your machine's local IP instead of localhost

## License

MIT License - See LICENSE file for details.

## Support

For issues and feature requests, please open an issue on GitHub.
