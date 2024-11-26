#!/bin/bash

MAX=100
DAYS_OLD=7
REPO="nhsuk/manage-vaccinations-in-schools"
PR_PREFIX="mavis-pr-"

usage() {
  echo "Usage: bash $0 [-h|--help]"
  echo
  echo "Delete GitHub review app environments older than $DAYS_OLD days."
  echo "Requires GitHub CLI (gh) to be installed and authenticated."
  echo
  echo "Options:"
  echo "  -h, --help    Show this help message"
  exit 0
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
fi

fetch_old_review_apps() {
  gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$REPO/environments?per_page=$MAX" | \
    jq -r --arg days "$DAYS_OLD" '
      .environments[] |
      select((now - (.updated_at | fromdateiso8601)) / 86400 > ($days | tonumber)) |
      .name
    ' | \
    grep "$PR_PREFIX"
}

echo "Fetching review apps older than $DAYS_OLD days (max: $MAX)..."
OLD_REVIEW_APPS=$(fetch_old_review_apps)

if [ -z "$OLD_REVIEW_APPS" ]; then
  echo "No old review apps found"
  exit 0
fi

for env in $OLD_REVIEW_APPS; do
  echo "Deleting review app: $env"
  gh api \
    --method DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$REPO/environments/$env"
done
