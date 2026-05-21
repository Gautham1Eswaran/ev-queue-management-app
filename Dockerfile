# 1. Use a standard Dart image for building
FROM dart:stable AS build

WORKDIR /app

# 2. Copy only the files needed for dependencies
COPY pubspec.yaml ./

# 3. Create a temporary 'dummy' lib/main.dart so pub get doesn't complain about Flutter
# and remove Flutter-only dependencies from the build-time pubspec
RUN sed -i \
    -e '/flutter:/d' \
    -e '/sdk: flutter/d' \
    -e '/google_fonts:/d' \
    -e '/fl_chart:/d' \
    -e '/provider:/d' \
    -e '/logger:/d' \
    -e '/intl:/d' \
    -e '/shared_preferences:/d' \
    -e '/flutter_test:/d' \
    -e '/lints:/d' \
    -e '/flutter_launcher_icons:/d' \
    pubspec.yaml && \
    mkdir lib && touch lib/main.dart

# 4. Install only the backend dependencies (shelf, mongo_dart, etc.)
RUN dart pub get --no-precompile

# 5. Copy the rest of the server code
COPY bin/ bin/

# 6. Compile the server into a standalone executable
RUN dart compile exe bin/server.dart -o bin/server

# 7. Use a tiny runtime image for the final container
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

# 8. Set up the environment
EXPOSE 3001
ENV PORT=3001

# 9. Start the server
CMD ["/app/bin/server"]
