# Change these once and forget forever
$ENV = "dev"
$STATUS = "review ready"

gh pr edit --add-label $ENV --add-label $STATUS
