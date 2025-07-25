### Frontend - Flutter

This is the frontend component of the full-stack marketplace app. It’s built in Flutter 3.32.7 and communicates with the backend via a RESTful API. The app runs on web and desktop (Chrome, Edge, Windows, etc.).

---

## 🧩 Features

- User authentication (register, login, logout)
- Profile management (view, edit, delete)
- Listing browser with search filters
- Listing creation and editing with media attachments
- Media upload and deletion (supports images and video)
- Drag-and-drop reordering of media via long press
- Listings show thumbnails (first image, if present)
- Media viewer with image zoom and video playback controls

---

## 📁 Project Structure

```
frontend/
├── lib/
│   ├── main.dart                # Entry point of the Flutter app
│   ├── screens/                 # UI screens (Login, Listings, Media Manager, etc.)
│   ├── services/                # Handles API calls to the backend
│   ├── utils/
│   │   ├── app_helpers.dart     # Utility functions used across the app (e.g., media URL builder)
│   │   └── constants.dart       # Centralized constants (e.g., API base URL)
├── assets/                      # Static assets (images, icons, branding, etc.)
├── pubspec.yaml                 # Flutter project metadata and dependencies
└── README.md                    # Project documentation
```

---

## 🧰 Development Environment

Built and tested using:

```java
Flutter 3.32.7 • channel stable • https://github.com/flutter/flutter.git
Framework • revision d7b523b356 (2025-07-15)
Engine • revision 39d6d6e699
Tools • Dart 3.8.1 • DevTools 2.45.1
```

---

## 🚀 Setup

Make sure Flutter is installed and working (`flutter doctor`). Then:

```bash
flutter pub get
flutter run -d chrome     # or edge, windows, etc.
```

To update the API base URL used by the app, edit:

```
lib/utils/constants.dart
```

---

## 🧪 Test Credentials

To quickly access the app, use the following seeded test account:

```bash
Username: prof.farwell
Password: password123
```

You can modify or remove this in `backend/scripts/seed_data.py`.
