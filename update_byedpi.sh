#!/bin/bash

REPO="https://github.com/hufrea/byedpi"
MODULE_PATH="Sources/ByeDPIC"
DOWNLOADED_COMMIT_ID_PATH="$MODULE_PATH/commit-id"
SUBMODULE_PATH="$MODULE_PATH/byedpi"

LAST_COMMIT_ID=$(git ls-remote "$REPO" HEAD | cut -f 1)
echo "Remote repo last commit - $LAST_COMMIT_ID"
DOWNLOADED_COMMIT_ID=""
if [[ -f "$DOWNLOADED_COMMIT_ID_PATH" ]]; then
    read -r DOWNLOADED_COMMIT_ID < "$DOWNLOADED_COMMIT_ID_PATH"
fi
echo "Cloned repo last commit - $DOWNLOADED_COMMIT_ID"

if [[ "$LAST_COMMIT_ID" == "$DOWNLOADED_COMMIT_ID" ]]; then
    echo "Commit ID from remote repo is equal to downloaded"
    echo "No need to update byedpi module"
    exit 0
fi

# Re-clone byedpi with the latest commit
echo "Remove old byedpi sources at $SUBMODULE_PATH"
rm -rf "$SUBMODULE_PATH"
git clone --depth 1 "$REPO" "$SUBMODULE_PATH"
if [[ -d "$SUBMODULE_PATH" ]]; then
  echo "$LAST_COMMIT_ID" > "$DOWNLOADED_COMMIT_ID_PATH"
fi

# Prepare cloned directory
echo "Prepare cloned directory for work at $SUBMODULE_PATH"
rm -rf "$SUBMODULE_PATH/.git"
rm -rf "$SUBMODULE_PATH/.github"
rm -rf "$SUBMODULE_PATH/dist"
rm -f "$SUBMODULE_PATH/.dockerignore"
rm -f "$SUBMODULE_PATH/.editorconfig"
rm -f "$SUBMODULE_PATH/Dockerfile"
rm -f "$SUBMODULE_PATH/Makefile"
rm -f "$SUBMODULE_PATH/README.md"
# rm -f "$SUBMODULE_PATH/win_service.h"
# rm -f "$SUBMODULE_PATH/win_service.c"
[ -f "$SUBMODULE_PATH/main.c" ] && mv "$SUBMODULE_PATH/main.c" "$SUBMODULE_PATH/ciadpi_main.c"
sed -i "" "s|#define DAEMON|//#define DAEMON|g" "$SUBMODULE_PATH/ciadpi_main.c"
