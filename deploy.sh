#!/bin/bash

# Deploy Jekyll site to Firebase Hosting
# This script builds the Jekyll site and deploys it to Firebase

echo "Building Jekyll site..."

# Option 1: Using Docker (recommended if Jekyll setup is problematic)
if command -v docker &> /dev/null; then
    echo "Using Docker to build Jekyll site..."
    docker run --rm -v "$PWD":/srv/jekyll jekyll/jekyll:4 jekyll build
else
    # Option 2: Using local Jekyll installation
    echo "Using local Jekyll installation..."
    if command -v bundle &> /dev/null; then
        bundle install
        bundle exec jekyll build
    else
        echo "Error: Neither Docker nor Bundle found. Please install one of them."
        exit 1
    fi
fi

echo "Jekyll build complete!"

# Deploy to Firebase
if command -v firebase &> /dev/null; then
    echo "Deploying to Firebase..."
    firebase deploy
else
    echo "Error: Firebase CLI not found. Please install it with: npm install -g firebase-tools"
    echo "Then run: firebase login && firebase init"
    exit 1
fi

echo "Deployment complete!"