# Git

## 1. How Do I…

| Key Combination | Action | Search terms |
|---|---|---|
| `Space g h` | See the git history (commits) of the current file. | log commits file history this opened buffer open telescope bcommits |
| `Space g h` (visual) | See the git history of the selected lines only. | log commits lines selection range who changed |
| `Space g c` | See the git history (all commits) of the whole repo / project. | log commits repo repository project telescope |
| `Space g s` | See git status: which files are changed / modified / staged. | changed modified files status diff telescope |
| `Space h d` | See the changes (diff) of the current file vs. staged. | diff changes current file this opened modified |
| `Space h D` | See the changes (diff) of the current file vs. last commit. | diff changes current file this opened HEAD |
| `]c` / `[c` | Jump to the next / previous change in the current file. | changes hunk navigate next previous modified diff |
| `Space h p` | Preview what changed at the cursor (hunk). | changes diff hunk preview popup |
| `Space h b` | See who changed this line and in which commit (blame). | blame author who line commit annotate |
| `Space t b` | Show blame on every line as you move (toggle). | blame author who line inline toggle annotate |
| `:Gitsigns blame` | Blame the whole current file. | blame author who file annotate |
| `Space h s` | Stage the change at the cursor. | stage add hunk |
| `Space h S` | Stage the whole current file. | stage add file |
| `Space h r` | Undo / discard the change at the cursor. | discard reset revert undo restore hunk |
| `Space h R` | Undo / discard all changes in the current file. | discard reset revert undo restore file |
| `Space g h`, then `Ctrl + V` | Compare current file with an older version (pick commit, diff side by side). | diff old version previous commit compare file history |
| `Space g b` | Switch / checkout / create / delete a branch. | branch checkout switch create delete merge rebase |
| `Space g S` | See and apply stashes. | stash apply pop saved |
| `Space g g` | Open LazyGit (commit, push, pull, everything). | commit push pull lazygit ui |
| `Space g w` | Switch git worktree (opens in its own kitty tab). | worktree switch tab |

## 2. Current File Changes (Gitsigns)

### Navigate & Inspect

| Key Combination | Action | Search terms |
|---|---|---|
| `]c` | Jump to the next git change (hunk) in the file. | changes modified next |
| `[c` | Jump to the previous git change (hunk) in the file. | changes modified previous |
| `Space h p` | Preview the hunk under the cursor in a popup. | changes diff |
| `Space h i` | Preview the hunk inline (old lines shown in the buffer). | changes diff |
| `Space h d` | Diff the current file against the index (staged version). | changes compare this opened |
| `Space h D` | Diff the current file against the last commit. | changes compare HEAD this opened |
| `Space h q` | Put all changes of this file in the quickfix list. | list changes current file |
| `Space h Q` | Put all changes of the whole repo in the quickfix list. | list changes all files project |
| `ih` | Text object: select the hunk (e.g. vih, dih). | select hunk change |

### Stage & Reset

| Key Combination | Action | Search terms |
|---|---|---|
| `Space h s` | Stage the hunk under the cursor (or the visual selection). | add change |
| `Space h r` | Reset (discard) the hunk under the cursor (or the visual selection). | undo revert restore change |
| `Space h S` | Stage the whole file. | add current file |
| `Space h R` | Reset (discard) all changes in the file. | undo revert restore current file |

### Blame

| Key Combination | Action | Search terms |
|---|---|---|
| `Space h b` | Full blame (commit message + diff) for the current line. | who author history line |
| `Space t b` | Toggle inline blame at the end of the current line. | who author |
| `Space t w` | Toggle intra-line word diff. | changes words |
| `:Gitsigns blame` | Blame the whole file in a side window. | who author current file |

## 3. History, Status & Branches (Telescope)

| Key Combination | Action | Search terms |
|---|---|---|
| `Space g h` | File history: commits that touched the current file (preview shows the diff). | log commits this opened buffer bcommits |
| `Space g h` (visual) | Line history: commits that touched the selected lines. | log commits selection range |
| `Space g c` | All commits in the repo. | log history project repository |
| `Space g s` | Git status: changed files with diff preview; Tab stages/unstages. | changed modified files stage diff |
| `Space g b` | Branches; Enter checks out. | switch checkout |
| `Space g S` | Stashes; Enter applies. | stash pop |
| `Space g f` | Search git-tracked files only. | find files tracked |

### Inside a Commit Picker

| Key Combination | Action | Search terms |
|---|---|---|
| `Enter` | Check out the commit (detached HEAD). | git history log |
| `Ctrl + V` | Diff the file against that commit in a vertical split (file history). | git compare old version |
| `Ctrl + X` | Diff the file against that commit in a horizontal split (file history). | git compare old version |
| `Ctrl + T` | Diff the file against that commit in a new tab (file history). | git compare old version |
| `Ctrl + R`, then `M` | Reset mixed to the commit (repo commits). | git undo |
| `Ctrl + R`, then `S` | Reset soft to the commit (repo commits). | git undo |
| `Ctrl + R`, then `H` | Reset hard to the commit (repo commits). | git undo |

### Inside the Branch Picker

| Key Combination | Action | Search terms |
|---|---|---|
| `Enter` | Check out the branch. | git switch |
| `Ctrl + A` | Create a new branch named after the prompt text. | git new |
| `Ctrl + D` | Delete the branch. | git remove |
| `Ctrl + Y` | Merge the branch into the current one. | git |
| `Ctrl + R` | Rebase the current branch onto it. | git |
| `Ctrl + T` | Track the remote branch. | git upstream |

## 4. LazyGit & Worktrees (Neovim)

| Key Combination | Action |
|---|---|
| `Space g g` | Open LazyGit in a floating window. |
| `Space g w` | Pick a git worktree; jumps to (or opens) its kitty tab. |

## 5. LazyGit Keys

### Global

| Key Combination | Action |
|---|---|
| `1` – `5` | Focus panel: status, files, branches, commits, stash. |
| `[` / `]` | Previous / next tab inside a panel. |
| `?` | Show all keybindings for the current panel. |
| `/` | Filter / search the current panel. |
| `z` | Undo the last git action (reflog based). |
| `Ctrl + Z` | Redo. |
| `+` / `_` | Next / previous screen mode (full screen panel). |
| `P` | Push. |
| `p` | Pull. |
| `:` | Run a shell command. |
| `Ctrl + R` | Switch to a recent repo. |
| `q` | Quit LazyGit. |

### Files Panel

| Key Combination | Action |
|---|---|
| `Space` | Stage / unstage the selected file. |
| `a` | Stage / unstage all files. |
| `Enter` | Open the file to stage individual lines / hunks. |
| `c` | Commit (message prompt). |
| `C` | Commit using the git editor. |
| `Ctrl + G` | Generate commit message with Gemini (custom). |
| `A` | Amend the last commit with staged changes. |
| `d` | Discard changes of the selected file. |
| `D` | Reset options (hard reset, nuke working tree, …). |
| `e` | Edit file in Neovim (closes LazyGit float). |
| `s` | Stash all changes. |
| `S` | Stash options (staged only, keep index, …). |
| `i` | Add file to .gitignore. |
| `f` | Fetch. |

### Staging View (after Enter on a file)

| Key Combination | Action |
|---|---|
| `Space` | Stage / unstage the selected line. |
| `v` | Start a range selection. |
| `a` | Toggle selecting the whole hunk. |
| `Tab` | Switch between unstaged and staged side. |
| `Esc` | Back to the files panel. |

### Branches Panel

| Key Combination | Action |
|---|---|
| `Space` | Check out the selected branch. |
| `n` | New branch from the selected one. |
| `M` | Merge the selected branch into the current one. |
| `r` | Rebase the current branch onto the selected one. |
| `R` | Rename branch. |
| `d` | Delete branch. |
| `u` | Upstream options (set / unset / push to). |
| `f` | Fast-forward the branch from its upstream. |

### Commits Panel

| Key Combination | Action |
|---|---|
| `Enter` | View the files changed in the commit. |
| `Ctrl + S` | Filter the log (e.g. only commits touching a path). |
| `r` | Reword the commit message. |
| `s` | Squash into the commit below. |
| `f` | Fixup into the commit below (drop message). |
| `e` | Edit the commit (interactive rebase). |
| `d` | Drop the commit. |
| `Ctrl + J` / `Ctrl + K` | Move the commit down / up. |
| `C` | Copy commit (cherry-pick). |
| `V` | Paste copied commits. |
| `t` | Revert the commit. |
| `T` | Tag the commit. |
| `g` | Reset to this commit (soft / mixed / hard). |
| `y` | Copy commit hash / message / URL. |

### Worktrees Tab (Branches panel)

| Key Combination | Action |
|---|---|
| `o` | Open the worktree in its own kitty tab with Neovim (custom). |
| `n` | New worktree. |
| `d` | Remove worktree. |

## 6. Git CLI

| Command | Action |
|---|---|
| `git status -sb` | Short status with branch info. |
| `git diff` | Unstaged changes. |
| `git diff --staged` | Staged changes. |
| `git diff -- path` | Changes of one file. |
| `git log --oneline --graph --all` | Compact history graph of all branches. |
| `git log -p -- path` | Full history of a file with diffs. |
| `git log --follow -- path` | History of a file across renames. |
| `git log -S "text"` | Commits that added/removed "text". |
| `git show <hash>` | Show a commit's message and diff. |
| `git blame -L 10,20 path` | Who changed lines 10–20 of a file. |
| `git restore path` | Discard unstaged changes of a file. |
| `git restore --staged path` | Unstage a file. |
| `git commit --amend --no-edit` | Add staged changes to the last commit. |
| `git switch -c name` | Create and switch to a new branch. |
| `git stash push -m "msg"` | Stash changes with a message. |
| `git stash pop` | Re-apply and drop the latest stash. |
| `git reset --soft HEAD~1` | Undo the last commit, keep changes staged. |
| `git reflog` | Every HEAD position — recover "lost" commits. |
| `git worktree add ../dir branch` | Check out a branch in a separate directory. |
