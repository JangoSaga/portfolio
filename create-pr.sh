#!/bin/bash

branch=$(git branch --show-current)

# Extract PREFRO-219
ticket=$(echo "$branch" | grep -oE 'prefro-[0-9]+' | tr 'a-z' 'A-Z')

# Extract readable title
title=$(echo "$branch" | sed -E 's/prefro-[0-9]+-//' | tr '-' ' ')

# Collect commit links
commits=$(git log origin/cohort..HEAD --oneline)

body="## Commits
$commits"

gh pr create \
  --base cohort \
  --title "[$ticket] $title" \
  --body "$body"
