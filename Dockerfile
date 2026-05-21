# 1. Use a standard Dart image for building
FROM dart:stable AS build

WORKDIR /app

# 2. Create a clean, server-only pubspec.yaml inside the container
# This avoids any conflicts with Flutter dependencies
RUN echo "name: ev_a_server" > pubspec.yaml && \
    echo "environment:" >> pubspec.yaml && \
    echo "  sdk: '>=3.0.0 <4.0.0'" >> pubspec.yaml && \
    echo "dependencies:" >> pubspec.yaml && \
    echo "  shelf: ^1.4.1" >> pubspec.yaml && \
    echo "  shelf_router: ^1.1.2" >> pubspec.yaml && \
    echo "  shelf_cors_headers: ^0.1.5" >> pubspec.yaml && \
    echo "  mongo_dart: ^0.8.1" >> pubspec.yaml && \
    echo "  crypto: ^3.0.3" >> pubspec.yaml

# 3. Download the backend-only dependencies
RUN dart pub get

# 4. Copy the server source code
COPY bin/ bin/

# 5. Compile the server into a standalone binary
RUN dart compile exe bin/server.dart -o bin/server

# 6. Use a minimal runtime image
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

# 7. Set up the environment (Render uses PORT env var)
EXPOSE 3001
ENV PORT=3001

# 8. Run the server
CMD ["/app/bin/server"]
