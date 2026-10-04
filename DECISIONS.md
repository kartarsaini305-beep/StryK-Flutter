# Decisions

Product and engineering choices made while building StryK. Update this file whenever a default is locked in.

## Step 1

- **Project path:** `/Users/kartarsaini/StryK` (no `Projects/` or `Developer/` folder on this machine).
- **Expo SDK 57** with the default Expo Router template (`src/app`), TypeScript strict, development builds later (not Expo Go) once native modules for maps and background location land.
- **Bundle id / package:** `com.stryk.app`.
- **Dark theme only** (`userInterfaceStyle: dark`). Light mode is out of scope for v1.
- **Fonts loaded at runtime** with `expo-font` + `@expo-google-fonts` so web and Expo Go previews work before a custom native build. We can switch to the config-plugin embed at store-build time.
- **Custom drawer**, not React Navigation Drawer: 82% width, max 330 px, left-edge swipe, hamburger → X, staggered item fade. This matches the spec more closely than the stock drawer.
- **Welcome stays at `/`**. Authenticated screens live under `/(app)` (`/home`, `/streak`, `/share`, `/gym`, `/profile`) so the app bar never appears on auth.
- **Auth and gym picker are scaffolds** until steps 2–3. Temporary “Continue to the app” / “Send OTP” buttons route to `/home` so the shell can be demoed.
- **Zustand** holds drawer open state and a mock `currentStreak` (0) until server streak exists.
- **Logo** is a React wordmark (`<Logo />`): heavy Bricolage Grotesque “StryK” with an amber rectangle behind “r”. No PNG/SVG assets were provided.
- **Stack transitions:** Expo Router / `react-native-screens` on this SDK does not expose `fade_from_right`. We use `ios_from_right` (fade + horizontal slide on iOS; closest match on Android).
