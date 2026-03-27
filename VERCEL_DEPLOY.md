# 🚀 Sleep Coach Backend - Vercel Deploy

## קישור ישיר להעלאה ל-Vercel

לחץ על הקישור למטה כדי להעלות את ה-Backend ל-Vercel עם כל ההגדרות מוכנות:

### 🔗 [Deploy to Vercel](https://vercel.com/new/clone?repository-url=https://github.com/gshlomi/sleep-coach-ios&name=sleep-coach-backend&teamId=team_ZlJa5JqqcwMhI6qMgCrOVoSW&root-directory=Backend)

---

## 📋 הגדרות ידניות (אם הקישור לא עובד)

אם הקישור לא פותח אוטומטית, הנה ההגדרות המלאות:

### שלב 1: ייבוא הפרויקט
1. לך ל-[vercel.com/new](https://vercel.com/new)
2. בחר **Import Git Repository**
3. חפש `gshlomi/sleep-coach-ios`
4. לחץ **Import**

### שלב 2: הגדרות Build

| שדה | ערך |
|-----|-----|
| **Project Name** | `sleep-coach-backend` |
| **Root Directory** | `Backend` |
| **Framework Preset** | Node.js |
| **Build Command** | (ריק - אין צורך ב-build) |
| **Output Directory** | (ריק) |
| **Install Command** | `npm install` |

### שלב 3: Environment Variables

הוסף את המשתנים הבאים ב-**Environment Variables**:

```
JWT_SECRET=sleep-coach-secret-2026-goldy-xyz123
NODE_ENV=production
PORT=3000
```

### שלב 4: Deploy
לחץ **Deploy** והמתן 2-3 דקות לסיום.

---

## 🎯 אחרי ההעלאה

### ה-URL יהיה זמין בפורמט:
```
https://sleep-coach-backend-goldy.vercel.app
```

### בדיקת תקינות:
```bash
curl https://sleep-coach-backend-goldy.vercel.app/api/health
```

אם תקבל `{ "status": "ok" }` - השרת עובד! ✅

---

## 📱 עדכון האפליקציה

לאחר שהשרת יעלה, תצטרך לעדכן את ה-iOS App:

### קובץ: `iOS/SleepCoach/Services/APIService.swift`

```swift
// שורה 8 - שנה את ה-URL ל-URL האמיתי מ-Vercel
static let baseURL = "https://sleep-coach-backend-goldy.vercel.app"
```

או פשוט תשאיר את זה כ-`<YOUR_VERCEL_URL>` ותעדכן ידנית ב-Xcode.

---

## 🔗 API Endpoints זמינים

לאחר ההעלאה, ה-API יהיה זמין בכתובות:

| Endpoint | Method | תיאור |
|----------|--------|-------|
| `/api/users/register` | POST | הרשמת משתמש חדש |
| `/api/users/login` | POST | התחברות |
| `/api/sleep/logs` | GET/POST | קבלה/שמירה של יומני שינה |
| `/api/insights/weekly` | GET | ניתוח שבועי |
| `/api/insights/monthly` | GET | ניתוח חודשי |
| `/api/insights/recommendations` | GET | המלצות מותאמות אישית |

---

## 📝 תיעוד מלא

- **API Documentation**: `API/openapi.yaml`
- **Project Overview**: `PROJECT.md`
- **Deployment Guide**: `DEPLOY.md`

---

## 🆘 תמיכה

אם משהו לא עובד:
1. בדוק את ה-Logs ב-Vercel Dashboard
2. וודא ש-`Backend/vercel.json` תקין
3. בדוק ש-Environment Variables הוגדרו נכון

---

**בהצלחה! 🌙✨**
