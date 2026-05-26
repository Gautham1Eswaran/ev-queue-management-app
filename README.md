# EV Charge Park 🔋

A comprehensive EV Charging Management System featuring a high-performance **Flutter** mobile/web application and a scalable **Dart (Shelf)** backend with **MongoDB Atlas** integration.

## 🚀 Overview

EV Charge Park is designed to streamline the electric vehicle charging experience. It manages real-time charging sessions, maintains a dynamic user queue, and provides an intelligent charging estimator to predict time and costs.

### ✨ Key Features

- **Real-Time Dashboard**: Monitor active charging sessions with live progress bars and countdown timers.
- **Smart Queue Management**: View your position in line and estimated wait times calculated dynamically.
- **Intelligent Estimator**: Calculate charging time, energy (kWh) needed, and total cost based on battery capacity and charger power.
- **Unified Profile**: Manage user details, car models, and parking spots with persistent cloud storage.
- **Adaptive Theming**: Full support for both Light and Dark modes with seamless transitions.
- **Cross-Platform**: Ready for Android and Web.

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Dart (Shelf Framework)
- **Database**: MongoDB Atlas (Cloud)
- **State Management**: Provider
- **Real-Time Logic**: Periodic polling & Local simulation interpolation

## 📸 Screenshots

| Dashboard (Light) | Dashboard (Dark) | Profile Settings |
| :---: | :---: | :---: |
| *Place screenshot here* | *Place screenshot here* | *Place screenshot here* |

*(Add your images to the `/screenshots` folder and update these links)*

## 📦 Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
- [Dart SDK](https://dart.dev/get-started/sdk)
- [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) account

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Gautham1Eswaran/ev_a.git
   cd ev_a
   ```

2. **Frontend Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Backend Configuration**:
   Create a `.env` file in the root directory (refer to `.env.example`):
   ```env
   MONGODB_URL=your_mongodb_connection_string
   PORT=3001
   ```

## 🏃 Running the Project

### 1. Start the Backend Server
```bash
dart run bin/server.dart
```

### 2. Run the Flutter App
- **Android**:
  ```bash
  flutter run
  ```
- **Web**:
  ```bash
  flutter run -d chrome
  ```

## 📂 Folder Structure

```text
ev_a/
├── bin/            # Backend server source code
├── lib/            # Flutter application source code
│   ├── models/     # Data models
│   ├── providers/  # State management (Provider)
│   ├── screens/    # UI Screens (Auth, Dashboard, Profile, etc.)
│   ├── services/   # API communication logic
│   └── utils/      # Helpers (Token management, etc.)
├── web/            # Web platform configuration
├── android/        # Android platform configuration
├── assets/         # App icons and static assets
└── screenshots/    # Project preview images
```

## 🔮 Future Improvements

- [ ] WebSocket integration for instant real-time updates.
- [ ] Push notifications for "Charging Complete" and "Queue Status."
- [ ] Map integration to find the nearest available charger.
- [ ] Payment gateway integration for automated billing.

## ⚖️ License

Distributed under the MIT License. See `LICENSE` for more information.

## 👤 Author

**Gautham Eswaran**
- GitHub: [@Gautham1Eswaran](https://github.com/Gautham1Eswaran)

---
*Developed with ❤️ for a better EV future.*
