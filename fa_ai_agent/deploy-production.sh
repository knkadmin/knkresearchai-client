#!/bin/bash

# Build the app for production with production environment
flutter build web --release --dart-define=FLUTTER_ENV_PRODUCTION=true

# Deploy to Firebase production
firebase deploy --only hosting:knkresearchai --project knkresearchai 