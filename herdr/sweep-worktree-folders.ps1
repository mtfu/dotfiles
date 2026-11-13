# Delete empty C:\repos\wt-* folders left behind by removed worktrees. On Windows git can't delete a worktree's
# folder while a process still has it as its working directory, so the empty folder stays. A live worktree always
# holds a .git file, so only leftovers are empty. Folders still locked are skipped and caught on the next run.
Get-ChildItem C:\repos -Directory -Filter 'wt-*' -ErrorAction SilentlyContinue |
    Where-Object { -not (Get-ChildItem -Force $_.FullName -ErrorAction SilentlyContinue) } |
    ForEach-Object { Remove-Item $_.FullName -ErrorAction SilentlyContinue }
