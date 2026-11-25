#!/bin/bash
set -e
cd "$(dirname "$0")"

if ! command -v node &> /dev/null; then
  echo "Node.js is required. Install it from https://nodejs.org"
  exit 1
fi

if ! command -v npm &> /dev/null; then
  echo "npm is required. Install Node.js from https://nodejs.org"
  exit 1
fi

echo "Installing dependencies..."
npm install

echo "Launching dialog..."
npx electron .
