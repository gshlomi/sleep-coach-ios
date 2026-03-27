# Sleep Coach App Store Deployment Guide 🚀

## Prerequisites

Before deploying to the App Store, ensure you have:

1. **Apple Developer Account**
   - Active Apple Developer Program membership ($99/year)
   - Access to [App Store Connect](https://appstoreconnect.apple.com)

2. **Xcode Configuration**
   - Xcode 15+ installed
   - Valid signing certificates

3. **App Store Connect Preparation**
   - App icon (1024x1024 PNG)
   - Screenshots for all device sizes
   - Privacy policy URL
   - App description and keywords

## Pre-Submission Checklist

### Code Configuration

- [ ] **Bundle Identifier**: Set to a unique identifier (e.g., `com.sleepcoach.app`)
- [ ] **Version Number**: Update `MARKETING_VERSION` in `project.yml` (e.g., `1.0.0`)
- [ ] **Build Number**: Update `CURRENT_PROJECT_VERSION` in `project.yml` (e.g., `1`)
- [ ] **Display Name**: "Sleep Coach" in `Info.plist`
- [ ] **Bundle Display Name**: Localized variants if needed

### Capabilities

- [ ] **HealthKit**: Enabled with proper entitlements
- [ ] **Push Notifications**: Configured (for future APNs integration)
- [ ] **Background Modes**: Fetch and Processing enabled

### Info.plist Keys

Required for HealthKit:
```
NSHealthShareUsageDescription - "Sleep Coach needs access to your health data to import sleep information from Apple Watch and provide accurate sleep analysis."
NSHealthUpdateUsageDescription - "Sleep Coach needs access to update your health data to save your sleep logs."
```

### Privacy & Legal

- [ ] **Privacy Policy**: Published URL required
- [ ] **Age Rating**: Complete age rating questionnaire
- [ ] **Copyright**: Company name or personal name

## Build Configuration

### Development Build

```bash
cd iOS
xcodegen generate
xcodebuild -project SleepCoach.xcodeproj \
  -scheme SleepCoach \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

### Release Build

```bash
xcodebuild -project SleepCoach.xcodeproj \
  -scheme SleepCoach \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/SleepCoach.xcarchive \
  archive
```

## App Store Connect Setup

### 1. Create New App

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **+** → **New App**
3. Fill in:
   - **Platforms**: iOS
   - **Name**: Sleep Coach
   - **Primary Language**: English (or Hebrew)
   - **Bundle ID**: Select your registered bundle ID
   - **SKU**: sleepcoach-1-0-0

### 2. App Information

**Description (English):**
```
Sleep Coach helps you track and improve your sleep quality through:

🌙 Smart Sleep Tracking
Log your sleep manually or import from Apple Watch

📊 Detailed Analytics
View weekly and monthly sleep patterns with beautiful charts

💡 Personalized Insights
Get AI-powered recommendations based on your sleep data

⏰ Pre-Sleep Reminders
Never miss a wind-down routine with smart notifications

📈 Track Your Progress
Monitor your sleep streak and goal achievement

Privacy First: Your health data stays on your device.
```

**Keywords:**
```
sleep, tracker, health, fitness, rest, nap, dreaming, bedtime, alarm, wellness
```

**Category Selection:**
- Primary: Health & Fitness
- Secondary: Lifestyle

### 3. Pricing and Availability

- Set pricing tier (0 = Free or select paid tier)
- Configure territory availability
- Set release date preference

### 4. Upload Build

1. In Xcode, Product → Archive
2. In Organizer, select archive → Distribute App
3. Choose **App Store Connect** → **Upload**
4. Wait for processing (usually 10-15 minutes)

### 5. Submit for Review

After build processing:

1. Go to **App Store Connect** → **My Apps** → **Sleep Coach**
2. Select the uploaded build
3. Complete **App Review Information**
   - Contact notes
   - Demo account (if needed)
   - Attachments (optional)
4. Submit for review

## Review Process

### Typical Timeline
- **Initial Review**: 24-48 hours
- **Re-review after rejection**: 24 hours

### Common Rejection Reasons

1. **HealthKit Permissions Not Clear**
   - Ensure usage descriptions are specific
   - Don't request unnecessary health data types

2. **Missing Privacy Policy**
   - Publish a proper privacy policy URL
   - Include section on HealthKit data usage

3. **Screenshot Issues**
   - Use correct device frames
   - Follow screenshot guidelines exactly

4. **App Functionality**
   - Ensure all buttons work
   - Test on multiple devices
   - Verify offline functionality

### HealthKit Review Tips

For HealthKit apps, Apple reviewers check:
- Only request read access if update not needed
- Don't misuse HealthKit data
- Provide clear privacy policy
- Request only necessary data types

## Post-Launch

### After Approval

1. **Set Availability Date**
   - Choose manual or automatic release
   - Consider timezone for launch moment

2. **Promote on Social Media**
   - Prepare App Store preview video
   - Share launch announcement

3. **Monitor Reviews**
   - Respond to user feedback
   - Address issues quickly

### Update Process

For new versions:

1. Update version in `project.yml`
2. Build and archive
3. Upload to App Store Connect
4. Select new build in app details
5. Add what's new text
6. Submit for review

## Backend Deployment

### Option 1: Heroku

```bash
# Create Heroku app
heroku create sleep-coach-api

# Set environment variables
heroku config:set JWT_SECRET=your-secret
heroku config:set NODE_ENV=production

# Deploy
git push heroku main
```

### Option 2: Railway

1. Connect GitHub repository
2. Configure environment variables
3. Deploy automatically

### Option 3: VPS/Docker

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## Environment Configuration

### Production Environment Variables

```env
PORT=3000
NODE_ENV=production
JWT_SECRET=<generate-secure-random-string>
JWT_EXPIRES_IN=30d
DB_PATH=/var/lib/sleep-coach/production.db
```

### HTTPS Configuration

Production API must use HTTPS. Options:
- Reverse proxy (nginx) with SSL certificate
- Cloudflare proxy
- Managed certificates (Let's Encrypt)

## Security Checklist

- [ ] JWT secret is secure random (32+ characters)
- [ ] Database file is not publicly accessible
- [ ] CORS configured for production domains only
- [ ] Rate limiting enabled
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] Password hashing with sufficient cost factor

## Monitoring

### Backend Health Check

```
GET /health
Response: { "status": "healthy", "version": "1.0.0" }
```

### Recommended Monitoring

- Uptime monitoring (UptimeRobot, Pingdom)
- Error tracking (Sentry)
- Performance monitoring (New Relic, Datadog)
- Log aggregation (Papertrail, LogDNA)

## Troubleshooting

### "No eligible devices for_arch"
- Regenerate signing certificates
- Check provisioning profiles

### "HealthKit entitlement not found"
- Enable HealthKit capability in Xcode
- Regenerate provisioning profile

### "Build validation failed"
- Ensure bundle identifier matches App Store Connect
- Check version number format

### "API cannot be reached"
- Configure correct baseURL for production
- Ensure HTTPS is working
- Check firewall rules

## Support Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

Good luck with your submission! 🌙
