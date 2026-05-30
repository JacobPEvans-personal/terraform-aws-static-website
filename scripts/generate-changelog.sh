#!/usr/bin/env bash
set -euo pipefail

PREV_TAG=$(git describe --abbrev=0 --tags $(git rev-list --tags --skip=1 --max-count=1) 2>/dev/null || echo "")

if [ -z "$PREV_TAG" ]; then
  CHANGELOG=$(git log --pretty=format:"- %s (%h)" --no-merges)
else
  CHANGELOG=$(git log $PREV_TAG..HEAD --pretty=format:"- %s (%h)" --no-merges)
fi

echo "$CHANGELOG" > changelog.txt
