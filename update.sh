#!/bin/bash
set -euo pipefail

# Self-update script for the System Dialog app (build-from-source install).
# Pulls the latest code and rebuilds + relaunches the Mac app.

# Work from the repo root, no matter where this is run from.
cd "$(dirname "$0")"

echo "==> Checking for updates to System Dialog..."

# Make sure we're actually inside a git clone.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo ""
  echo "This folder isn't a git clone, so it can't update itself."
  echo "You likely downloaded the app instead of cloning it."
  echo "To get self-updates, re-install by cloning the repo:"
  echo ""
  echo "  git clone https://github.com/jljingjia67/system-dialog-builder.git"
  echo "  cd system-dialog-builder/native-app"
  echo "  ./build.sh"
  echo ""
  exit 1
fi

OLD_VERSION="$(git rev-parse --short HEAD)"
echo "==> Current version: ${OLD_VERSION}"

echo "==> Pulling the latest code..."
if ! git pull --ff-only; then
  echo ""
  echo "Couldn't pull the latest code. A couple of common reasons:"
  echo "  * No internet connection — check that you're online and try again."
  echo "  * You have local edits that block a clean update."
  echo "    Your changes are safe; this script won't touch them. Move or"
  echo "    revert them, then run ./update.sh again."
  echo ""
  exit 1
fi

NEW_VERSION="$(git rev-parse --short HEAD)"
if [ "${OLD_VERSION}" = "${NEW_VERSION}" ]; then
  echo "==> Already up to date."
else
  echo "==> Updated ${OLD_VERSION} -> ${NEW_VERSION}"
fi

echo "==> Rebuilding and relaunching the app..."
( cd native-app && ./build.sh )

echo "==> Done! System Dialog is up to date and running."
