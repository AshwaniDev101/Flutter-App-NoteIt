
### * Android
| Homepage | New Note | Search |
| :---: | :---: | :---: |
| <img src="docs/screenshots/android/android_homepage.jpg" width="250"/> | <img src="docs/screenshots/android/android_notepage.jpg" width="250"/> | <img src="docs/screenshots/android/android_search.jpg" width="250"/> |

| Sidebar | Theme Settings | Password Lock |
| :---: | :---: | :---: |
| <img src="docs/screenshots/android/android_sidebar.jpg" width="250"/> | <img src="docs/screenshots/android/android_theme_change.jpg" width="250"/> | <img src="docs/screenshots/android/android_enter_password.jpg" width="250"/> |

### * Windows
| Desktop Homepage | Desktop Sidebar |
| :---: | :---: |
| <img src="docs/screenshots/windows/desktop_homepage.jpg" width="400"/> | <img src="docs/screenshots/windows/desktop_Sidebar.JPG" width="400"/> |


# Note-It 

A minimal and fast cross-platform note-taking app that works seamlessly on Windows and Android. It syncs across platforms in real-time, and allows notes to be locked and password protected.

It allows two types of sync: first using Firebase, and second using WebSockets on a local WiFi network. This means the app doesn't require an internet connection to sync locally.

## # Features

- **Cross-Platform:** Smooth experience across Android and Windows.
- **Secure:** Built-in password protection to keep your private notes safe.
- **Google Integration:** Quick access via Google Sign-in.
- **Organization:** Easily filter, search, and manage notes.
- **Trash Bin:** Recover deleted notes before they're gone forever.
- **Customizable:** Light and dark theme support (including the custom amber theme!).

## # Tech Stack & Core Dependencies

This project relies on a robust set of packages to handle state, local storage, cloud syncing, and hardware interactions.

**Core & State Management**
- [Flutter](https://flutter.dev/) (SDK ^3.10.7)
- `flutter_riverpod` & `riverpod_annotation` - For predictable, compile-safe state management.

**Storage & Database**
- `drift` & `drift_flutter` - Reactive, type-safe persistence for local SQLite databases.
- `shared_preferences` - For lightweight local data and theme settings caching.
- `path_provider` - For locating local file system paths.

**Backend & Authentication**
- `firebase_core`, `cloud_firestore`, `firebase_auth` - Cloud data synchronization and backend infrastructure.
- `google_sign_in_all_platforms` - Seamless OAuth integration.

**Navigation**
- `go_router` - Declarative routing and deep linking.

**Hardware & Connectivity**
- `mobile_scanner` & `qr_flutter` - For scanning and generating QR codes.
- `web_socket_channel` & `nsd` - For real-time network service discovery and WebSocket communications.
- `device_info_plus` - For fetching specific device metadata.

**Dev Dependencies**
- `build_runner` & `drift_dev` - Code generation.
- `flutter_launcher_icons` - Automated app icon generation.
