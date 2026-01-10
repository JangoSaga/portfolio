# Get current branch and ticket info
$branch = git branch --show-current
$ticket = ($branch | Select-String -Pattern 'prefro-\d+' -AllMatches).Matches[0].Value.ToUpper()
$title = $branch -replace 'prefro-\d+-', '' -replace '-', ' '

# Prompt for description details
Write-Host "`nFilling PR Description Template for [$ticket]`n"

Write-Host "Task (What task does this address?):"
$task = Read-Host

Write-Host "`nAction (What changes were made?):"
$action = Read-Host

Write-Host "`nTesting (How was this tested?):"
$testing = Read-Host

# Build commit message with description details
$commitMessage = "[$ticket] $title" + "`n`n"
$commitMessage += "## Ticket`n"
$commitMessage += "$ticket : $title`n`n"
$commitMessage += "## Task`n"
$commitMessage += "$task`n`n"
$commitMessage += "## Action`n"
$commitMessage += "$action`n`n"
$commitMessage += "## Testing`n"
$commitMessage += "$testing"

# Stage all changes
Write-Host "`nStaging changes..."
git add -A

# Show what will be committed
Write-Host "`nFiles to be committed:"
git diff --cached --name-only

# Confirm before committing
$confirm = Read-Host "`nCommit these changes? (y/n)"

if ($confirm -eq "y" -or $confirm -eq "yes") {
  git commit -m $commitMessage
  Write-Host "`nChanges committed successfully!"
  Write-Host "Next step: Run './create-pr.ps1' to create the pull request"
} else {
  Write-Host "`nCommit cancelled"
  git reset
}
