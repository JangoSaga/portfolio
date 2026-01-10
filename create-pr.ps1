# Change these once and forget forever
$BASE_BRANCH = "main"

$branch = git branch --show-current

# Extract PREFRO-219
$ticket = ($branch | Select-String -Pattern 'prefro-\d+' -AllMatches).Matches[0].Value.ToUpper()

# Extract readable title
$title = $branch -replace 'prefro-\d+-', '' -replace '-', ' '

# Collect commit links
$commits = git log "$BASE_BRANCH..HEAD" --oneline

if (-not $commits) {
  $commits = "No commits to display"
}

$body = @"
## Commits
$commits
"@

gh pr create `
  --base $BASE_BRANCH `
  --title "[$ticket] $title" `
  --body $body
