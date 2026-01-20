# GitHub Wallpaper 📊

Turn your GitHub contribution graph into a live, auto-updating wallpaper on your Android phone.

![Version](https://img.shields.io/badge/version-1.0.0-green)
![Platform](https://img.shields.io/badge/platform-Android-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B)

## What is GitHub Wallpaper?

GitHub Wallpaper is a Flutter app that:
- Fetches your **monthly GitHub contribution data**
- Displays it as a beautiful **calendar heatmap**
- Sets it as your **lock screen and home screen wallpaper**
- **Auto-updates every 4 hours** in the background

Stay motivated by seeing your coding streak every time you unlock your phone!

---

## Screenshots

| Home Screen | Customize | Lock Screen |
|-------------|-----------|-------------|
| Live preview of your contribution graph | Adjust size and add quotes | Your wallpaper in action |

---

## Features

### 🏠 Home Screen
The home screen shows:
- **Live Preview** - Phone mockup showing exactly how your wallpaper will look
- **Quick Stats** - Total contributions this month, current streak, and today's commits
- **Sync Button** - Manually refresh your GitHub data
- **Auto-updates every 4 hours** indicator

### 🎨 Customize Screen
Personalize your wallpaper with:
- **Size Slider** - Make the contribution graph bigger or smaller
- **Custom Quote** - Add a motivational message below your stats

### 📊 Stats Screen
Detailed statistics about your GitHub activity:
- **Total Contributions** - How many commits/PRs/issues this month
- **Current Streak** - Consecutive days with contributions
- **Longest Streak** - Your best streak this month
- **Today's Commits** - Contributions made today
- **Contribution Breakdown** - Visual analysis of your activity
- **Best Day** - Your most productive day

### ⚙️ Settings Screen
- **Auto-Update Toggle** - Enable/disable background updates
- **Update Interval** - Choose 2, 4, 6, or 12 hours
- **Dark Mode** - Switch between light and dark themes
- **GitHub Account** - View or change your connected account
- **Clear Data** - Reset everything and start fresh

---

## Understanding the Graph Colors

The contribution graph uses GitHub's color scale:

| Color | Level | Meaning |
|-------|-------|---------|
| 🟩 Light Green | Level 1 | 1-3 contributions |
| 🟩 Medium Green | Level 2 | 4-6 contributions |
| 🟩 Dark Green | Level 3 | 7-9 contributions |
| 🟩 Darkest Green | Level 4 | 10+ contributions |
| ⬜ Gray/Empty | Level 0 | No contributions |

---

## Setup Guide

### Step 1: Generate GitHub Token

1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Click **"Generate new token (classic)"**
3. Give it a name like "Wallpaper App"
4. Select the **`read:user`** scope (minimum required)
5. Click **Generate token**
6. Copy the token (starts with `ghp_`)

### Step 2: Connect Your Account

1. Open the GitHub Wallpaper app
2. Enter your **GitHub username**
3. Paste your **Personal Access Token**
4. Tap **"Sync GitHub Data"**
5. Wait for data to load

### Step 3: Set Your Wallpaper

1. Go to **Customize** tab
2. Adjust the size if needed
3. Add a motivational quote (optional)
4. Tap **"Set Wallpaper"**
5. Choose: Lock Screen, Home Screen, or Both

That's it! Your wallpaper will now auto-update every 4 hours.

---

## How Auto-Update Works

Once you set your wallpaper, the app works in the background:

```
Every 4 hours:
  1. Fetch latest contribution data from GitHub
  2. Generate new wallpaper image
  3. Set it as your lock/home screen
  4. All automatic, no action needed!
```

You can change the interval in **Settings → Update Interval** (2/4/6/12 hours).

---

## FAQ

### Why do I need a GitHub token?

GitHub's API requires authentication to access your contribution data. The token only needs `read:user` permission - it cannot modify anything on your account.

### Is my token stored securely?

Yes, the token is stored locally on your device using Android's SharedPreferences with no network transmission except to GitHub's official API.

### The wallpaper isn't updating automatically?

1. Make sure **Auto-Update** is enabled in Settings
2. Disable battery optimization for this app
3. Ensure the app isn't being killed by your phone's battery saver

### How do I change my GitHub account?

Go to **Settings → GitHub Account** and enter new credentials.

---

## Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/github_wallpaper.git
cd github_wallpaper

# Install dependencies
flutter pub get

# Run on device
flutter run

# Build release APK
flutter build apk --release
```

### Requirements
- Flutter 3.38+
- Android SDK 21+ (Android 5.0 Lollipop)
- Dart 3.10+

---

## Tech Stack

- **Flutter** - Cross-platform UI framework
- **WorkManager** - Background task scheduling
- **GraphQL** - GitHub API queries
- **SharedPreferences** - Local data storage
- **async_wallpaper** - Native wallpaper setting

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Contributing

Pull requests are welcome! Please open an issue first to discuss major changes.

---

**Made with 💚 for GitHub enthusiasts**
