#!/usr/bin/env bash

# This script creates a new draft release and creates a template for the release notes. 
# It extracts pre-release and post-release tasks from pull request descriptions.
# The required syntax is:
# Pre-Release:
# - Task 1
# - Task 2
# Post-Release:
# - Task 3

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <release_tag>"
    exit 1
fi

release_tag=$1
latest_release=$(gh release list --json name,isLatest --jq '.[] | select(.isLatest)|.name')

merge_base=$(git merge-base origin/main origin/next)
pr_numbers=$(git log --pretty=format:"%s" $merge_base..origin/next | grep -oE 'Merge pull request #([0-9]+)' | grep -oE '[0-9]+')

pre_release_tasks=""
post_release_tasks=""

for pr in $pr_numbers; do
  echo "Processing PR #$pr"
  pr_body=$(gh pr view "$pr" --json body -q '.body')
  pre=$(echo "$pr_body" | sed -n '/Pre-Release:/,/Post-Release:/p' | grep '^[*-]' || true)
  post=$(echo "$pr_body" | sed -n '/Post-Release:/,$p' | grep '^[*-]' || true)

  if [ -n "$pre" ]; then
    pre_release_tasks+="
PR #$pr:
$pre
"
  fi
  if [ -n "$post" ]; then
    post_release_tasks+="
PR #$pr:
$post
"
  fi
done

release_body="**Full Changelog**: https://github.com/nhsuk/manage-vaccinations-in-schools/compare/$latest_release...$release_tag
"

if [ -n "$pre_release_tasks" ]; then
  release_body+="
## Pre-Release Tasks
${pre_release_tasks}
"
fi
if [ -n "$post_release_tasks" ]; then
  release_body+="
## Post-Release Tasks
${post_release_tasks}
"
fi

echo "$release_body" > release_notes.md
