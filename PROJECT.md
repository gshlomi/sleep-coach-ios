# Sleep Coach iOS App - Technical Documentation 🌙

## Overview

Sleep Coach is a comprehensive iOS application designed to help users track their sleep patterns, maintain consistent sleep schedules, and improve overall sleep quality through personalized insights and pre-sleep routine reminders.

## Technical Stack

### iOS Application
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Minimum iOS**: 17.0
- **Target Devices**: iPhone, iPad

### Backend API
- **Runtime**: Node.js 20+
- **Framework**: Express.js 4.18+
- **Database**: SQLite (better-sqlite3)
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: bcryptjs

## Project Architecture

### iOS App Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Views                                │
│  (OnboardingView, DashboardView, SleepLogView, etc.)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      ViewModels                             │
│  (SleepViewModel, InsightsViewModel)                         │
│  - @Published properties for reactive UI updates            │
│  - Business logic and data transformation                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Services                              │
│  APIService │ NotificationManager │ HealthKitManager       │
│  StorageManager                                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Models                               │
│  SleepLog │ UserPreferences │ SleepInsight                 │
└─────────────────────────────────────────────────────────────┘
```

### Backend Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Routes                                │
│  users.js │ sleep.js │ insights.js                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Services                               │
│  database.js │ auth.js │ sleepAnalyzer.js │ insightGenerator│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SQLite Database                           │
│  users │ sleep_logs │ pre_sleep_tasks │ task_completions    │
│  insights                                                   │
└─────────────────────────────────────────────────────────────┘
```

## Data Models

### iOS Models

#### SleepLog
```swift
struct SleepLog: Identifiable, Codable {
    let id: String
    let bedtime: Date
    let wakeTime: Date
    let sleepDurationMinutes: Int
    let sleepQuality: Int?  // 1-5 rating
    let notes: String?
    let preSleepTasksCompleted: [String]?
    let healthkitSynced: Bool
    let createdAt: Date
}
```

#### UserPreferences
```swift
struct UserPreferences: Codable {
    var plannedBedtime: Date
    var plannedWakeTime: Date
    var sleepGoalHours: Double
    var timezone: String
    var language: String  // "he" or "en"
    var notificationsEnabled: Bool
    var healthKitEnabled: Bool
}
```

#### SleepInsight
```swift
struct SleepInsight: Identifiable, Codable {
    let id: String
    let type: InsightType  // info, warning, recommendation, positive, concern
    let priority: InsightPriority  // high, medium, low
    let title: String
    let titleHe: String  // Hebrew translation
    let description: String
    let descriptionHe: String
    let action: String?
}
```

### Database Schema

#### users
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | UUID |
| email | TEXT UNIQUE | User email |
| password_hash | TEXT | bcrypt hashed password |
| name | TEXT | Display name |
| planned_bedtime | TEXT | HH:mm format |
| planned_wake_time | TEXT | HH:mm format |
| sleep_goal_hours | REAL | Target sleep hours |
| timezone | TEXT | IANA timezone |
| language | TEXT | "he" or "en" |
| created_at | TEXT | ISO8601 timestamp |
| updated_at | TEXT | ISO8601 timestamp |

#### sleep_logs
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | UUID |
| user_id | TEXT (FK) | References users.id |
| bedtime | TEXT | ISO8601 timestamp |
| wake_time | TEXT | ISO8601 timestamp |
| sleep_duration_minutes | INTEGER | Calculated duration |
| sleep_quality | INTEGER | 1-5 rating |
| notes | TEXT | User notes |
| pre_sleep_tasks_completed | TEXT | JSON array |
| healthkit_synced | INTEGER | 0 or 1 |
| created_at | TEXT | ISO8601 timestamp |

## API Specification

### Authentication

#### POST /api/users/register
**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "plannedBedtime": "23:00",
  "plannedWakeTime": "07:00",
  "sleepGoalHours": 8.0,
  "timezone": "Asia/Jerusalem",
  "language": "he"
}
```

**Response (201):**
```json
{
  "message": "User registered successfully",
  "user": { /* User object */ },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### POST /api/users/login
**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "message": "Login successful",
  "user": { /* User object */ },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### Sleep Logs

#### POST /api/sleep/logs
**Request:**
```json
{
  "bedtime": "2024-01-15T23:30:00Z",
  "wakeTime": "2024-01-16T07:15:00Z",
  "sleepQuality": 4,
  "notes": "Felt well rested",
  "preSleepTasksCompleted": ["breathing", "worry_list"],
  "healthkitSynced": false
}
```

**Response (201):**
```json
{
  "message": "Sleep log created successfully",
  "log": { /* SleepLog object */ }
}
```

### Insights

#### GET /api/insights/summary
**Response:**
```json
{
  "summary": {
    "streak": 7,
    "weeklyAverage": {
      "durationMinutes": 420,
      "durationHours": 7.0,
      "quality": 4.2
    },
    "consistencyScore": 85,
    "goalAchievementRate": 75,
    "sleepGoalHours": 8.0
  }
}
```

#### GET /api/insights/recommendations
**Response:**
```json
{
  "recommendations": [
    {
      "type": "positive",
      "priority": "medium",
      "title": "Breathing exercises improve your sleep by 20%",
      "titleHe": "תרגילי נשימה משפרים את השינה שלך ב-20%",
      "description": "You sleep significantly better when...",
      "descriptionHe": "אתה ישן הרבה יותר טוב כש...",
      "action": "task_breathing"
    }
  ],
  "generatedAt": "2024-01-16T10:30:00Z"
}
```

## Sleep Analysis Engine

### Consistency Score Calculation

The consistency score (0-100) measures how regular your sleep schedule is:

1. Extract bedtime hours (normalized to 24h format)
2. Extract wake time hours
3. Calculate standard deviation for both
4. Convert to score: `100 - (stdDev * 15)`
5. Average bedtime score, wake time score, and duration score

### Task Effectiveness Analysis

For each pre-sleep task type:
1. Find logs where task was completed vs not completed
2. Calculate average quality with and without task
3. Compute impact: `(qualityWith - qualityWithout) / qualityWithout * 100`

### Day of Week Analysis

1. Group logs by day of week (Sunday-Saturday)
2. Calculate average duration and quality per day
3. Compute composite score: `(durationScore * 0.4) + (qualityScore * 0.6)`
4. Rank days to find best/worst

## Pre-Sleep Task System

### Task Types

| Task | Minutes Before | Icon | Description |
|------|----------------|------|-------------|
| screen_shutdown | 120 | iphone.slash | Stop screen usage |
| wind_down | 60 | moon.stars | Begin relaxation |
| worry_list | 30 | list.bullet.clipboard | Journal worries |
| breathing | 15 | wind | 4-7-8 breathing |
| cognitive_shuffle | 5 | brain | Mental quieting |

### Notification Scheduling

Notifications are scheduled daily based on planned bedtime:
- Each notification fires at `bedtime - minutesBeforeBedtime`
- Repeats daily using `UNCalendarNotificationTrigger`
- Content localized based on user's language preference

## Localization

### Supported Languages
- English (en) - Default
- Hebrew (he) - RTL support

### Localization Strategy

1. All user-facing strings in `Localizable.strings`
2. Hebrew translations provided with `titleHe` and `descriptionHe` fields
3. UI uses `LocalizedStringKey` for SwiftUI string interpolation
4. RTL layout handled automatically by SwiftUI

### Key Translations

| Key | English | Hebrew |
|-----|---------|--------|
| Dashboard | Dashboard | לוח בקרה |
| Sleep Score | Sleep Score | ציון שינה |
| Log Sleep | Log Sleep | תעד שינה |
| Settings | Settings | הגדרות |

## HealthKit Integration

### Data Types

**Read Access:**
- `HKCategoryTypeIdentifier.sleepAnalysis` - Sleep samples

**Write Access:**
- None (read-only app)

### Sleep Sample Processing

1. Query samples from last 14 days
2. Filter for `inBed`, `asleepCore`, `asleepDeep`, `asleepREM`
3. Group by date to form complete sleep sessions
4. Estimate quality based on duration vs goal
5. Convert to `SleepLog` model

## Security

### Authentication
- JWT tokens with 7-day expiration
- Tokens required for all `/api/sleep/*` and `/api/insights/*` endpoints
- Token passed via `Authorization: Bearer <token>` header

### Password Security
- bcrypt hashing with cost factor 12
- Minimum 6 character password requirement

### Data Protection
- SQLite database stored in app's documents directory
- No sensitive data in UserDefaults (only non-critical preferences)
- HTTPS recommended for production API

## Error Handling

### iOS Error Handling
```swift
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case networkError(Error)
}
```

### Backend Error Format
```json
{
  "error": "Error Type",
  "message": "Human readable message",
  "timestamp": "ISO8601 timestamp"
}
```

## Performance Considerations

### iOS
- Lazy loading of sleep logs
- Local storage with sync-on-connect
- Background refresh for recommendations
- Efficient chart rendering with Charts framework

### Backend
- Indexed database queries
- Pagination for log retrieval
- Cached analysis results
- Connection pooling for SQLite

## Testing Strategy

### iOS Unit Tests
- ViewModel business logic
- Model encoding/decoding
- Date calculations

### Backend Integration Tests
- API endpoint testing
- Database operations
- Authentication flows

## Deployment

### Backend Deployment
1. Set environment variables
2. Run `npm install --production`
3. Start with `npm start`
4. Use process manager (PM2) for production

### iOS Deployment
1. Update version in `project.yml`
2. Configure signing team
3. Archive and export
4. Submit to App Store Connect

See `DEPLOY.md` for detailed deployment instructions.
