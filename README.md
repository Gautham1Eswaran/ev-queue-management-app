# EV Parking App Backend

A server app built using [Shelf](https://pub.dev/packages/shelf), 
connected to MongoDB Atlas, and configured for [Docker](https://www.docker.com/).

This server handles user registration and login for the EV Parking App.

## API Endpoints

- `POST /register`: Register a new user.
- `POST /login`: Authenticate a user.

## Running the Server

### Running with the Dart SDK

1. Make sure you have the [Dart SDK](https://dart.dev/get-dart) installed.
2. Run the server:
   ```bash
   dart run bin/server.dart
   ```
   The server will listen on port `3000` by default.

### Running with Docker

1. Build the image:
   ```bash
   docker build . -t ev-server
   ```
2. Run the container:
   ```bash
   docker run -it -p 3000:3000 ev-server
   ```

## Connecting from the Flutter App

- **Android Emulator**: Use `http://10.0.2.2:3000` as the base URL.
- **Physical Device**: Use your computer's local IP address (e.g., `http://192.168.x.x:3000`). Ensure both devices are on the same network.
- **iOS Simulator**: Use `http://localhost:3000`.

## Troubleshooting

If you cannot connect:
1. Ensure the server is running and says `Server listening on port 3000`.
2. Verify the MongoDB connection: The server should log `Connected to MongoDB Atlas successfully.`
3. Check your `baseUrl` in `lib/main.dart`.
4. If using a physical device, check your computer's firewall settings to allow incoming traffic on port 3000.
