# StryK

Gym check-in streaks for iOS and Android. Core promise: **Just show up. We keep the streak.**

This repo is an Expo (SDK 57) + TypeScript app. Step 1 is in place: design tokens, fonts, wordmark, welcome, and the app shell with an animated hamburger and drawer.

## Prerequisites

- Node 20+
- Xcode (iOS) and/or Android Studio
- Expo CLI via `npx`

A **development build** is required once maps, background location, and geofencing are added. For step 1 you can still preview on simulator/web.

## Setup

```bash
cd StryK
cp .env.example .env
npm install
npx expo start
```

Then press `i` for iOS simulator, `a` for Android, or `w` for web.

## What’s in step 1

- Dark design tokens, Bricolage Grotesque + DM Sans
- `<Logo />` wordmark (amber block behind **r**)
- Welcome, login/signup scaffolds, legal placeholders
- App bar (hamburger, logo, share) and left drawer with edge-swipe
- Placeholder Home / My streak / Share card / Change gym / Profile

Auth, maps, check-in, streaks, geofencing, and share cards come in later steps.

## Scripts

```bash
npx expo start
npx tsc --noEmit
npx expo lint
```
