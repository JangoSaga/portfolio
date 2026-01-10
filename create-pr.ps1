# Configuration
$BASE_BRANCHES = @("precize-main", "precize-stage", "precize-dev")
$LABEL_MAPPING = @{
  "precize-main" = "prod"
  "precize-stage" = "stage"
  "precize-dev" = "dev"
}

$branch = git branch --show-current

# Extract ticket (PREFRO-219)
$ticket = ($branch | Select-String -Pattern 'prefro-\d+' -AllMatches).Matches[0].Value.ToUpper()

# Extract readable title
$title = $branch -replace 'prefro-\d+-', '' -replace '-', ' '

# Find base branch and get commits
$BASE_BRANCH = "main"
$commits = @()

foreach ($baseBranch in $BASE_BRANCHES) {
  $result = git log "$baseBranch..HEAD" --oneline 2>$null
  if ($LASTEXITCODE -eq 0 -and $result) {
    $commits = $result
    $BASE_BRANCH = $baseBranch
    break
  }
}

if (-not $commits) {
  # Fallback: get last commit message which includes description
  $commits = git log -1 --format=%B
}

# Determine nearest parent branch and labels
$parentBranch = git rev-parse --abbrev-ref HEAD@{u} 2>$null | % { ($_ -split '/')[-1] }
$labels = @()

if ($parentBranch -match '^precize-(main|stage|dev)$') {
  # Scenario 1: Direct environment branch
  $labels += $LABEL_MAPPING[$parentBranch]
} elseif ($parentBranch -match '^precize-') {
  # Scenario 2: Feature branch
  $labels += @("feature", "dev")
} elseif ($parentBranch -match '^prefro-\d+') {
  # Scenario 3: Chained PR
  $labels += @("chained", "dev")
} else {
  # Default to dev
  $labels += "dev"
}

# Ask user about work status
Write-Host "`nIs your work done or still in progress?"
Write-Host "1. Done - add 'review ready' label"
Write-Host "2. In progress - add 'wip' label"
$choice = Read-Host "Enter choice 1 or 2"

if ($choice -eq "2") {
  $labels += "wip"
} else {
  $labels += "review ready"
}

# Prompt for PR description details
Write-Host "`nFilling PR Description Template for [$ticket]"
Write-Host "`nTask (What task does this address?):"
$task = Read-Host

Write-Host "`nAction (What changes were made?):"
$action = Read-Host

Write-Host "`nTesting (How was this tested?):"
$testing = Read-Host

# Build PR body with description
$body = "## Ticket`n"
$body += "$ticket : $title`n`n"
$body += "## Task`n"
$body += "$task`n`n"
$body += "## Action`n"
$body += "$action`n`n"
$body += "## Testing`n"
$body += "$testing"

# Create PR
Write-Host "Creating PR: [$ticket] $title"
$prOutput = gh pr create `
  --base $BASE_BRANCH `
  --title "[$ticket] $title" `
  --body "$body" 2>&1

if ($LASTEXITCODE -eq 0) {
  Write-Host "PR Created: $prOutput"
  
  # Extract PR number from output
  $prNumber = $prOutput | Select-String -Pattern '#\d+' -AllMatches | % { $_.Matches[0].Value }
  
  # Add labels
  Write-Host "Adding labels: $($labels -join ', ')"
  foreach ($label in $labels) {
    gh pr edit $prNumber --add-label $label
  }
  
  Write-Host "Labels added successfully!"
} else {
  Write-Host "Failed to create PR: $prOutput"
}
