#!/bin/bash

# Build the app for staging with staging environment
flutter build web --release --dart-define=FLUTTER_ENV_STAGING=true

# Deploy to Firebase staging
firebase deploy --only hosting:knkresearchai-staging --project knkresearchai-staging 