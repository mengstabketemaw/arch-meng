# Nvim Tree

Open / close the tree with `\` (it also jumps to the current file). All keys
below work inside the tree window. `g?` shows the built-in help.

## 1. How Do I…

| Key Combination | Action | Search terms |
|---|---|---|
| `\` | Open / close the file tree and reveal the current file. | toggle show hide explorer sidebar nvimtree find |
| `a` | Create a new file. End the name with `/` to create a folder (`a/b/c.txt` creates the folders too). | new add create file folder directory mkdir touch |
| `x` on file/folder, go to target folder, `p` | Move a file or folder (cut, then paste into the folder under the cursor). | move mv file folder directory cut paste relocate |
| `u` | Move a file or folder by editing its full path (e.g. change `src/a.lua` to `lib/a.lua`). | move mv file folder directory rename path relocate |
| `m` on each, then `bmv` | Move several marked files / folders at once (asks for the target folder). | move mv multiple many files folders bulk marked bookmark relocate |
| `c` on file/folder, go to target folder, `p` | Copy a file or folder (copy, then paste into the folder under the cursor). | copy duplicate cp file folder directory paste clone |
| `r` | Rename a file or folder (name only, keeps the folder). | rename file folder directory mv change name |
| `e` | Rename only the basename (keeps the extension). | rename file name extension |
| `d` | Delete a file or folder (asks to confirm). | delete remove rm file folder directory |
| `D` | Move a file or folder to the trash. | trash delete remove recycle file folder |
| `m` on each, then `bd` | Delete several marked files / folders at once. | delete remove rm multiple many bulk marked bookmark |
| `m` on each, then `bt` | Trash several marked files / folders at once. | trash delete multiple many bulk marked bookmark |
| `V` select lines, then `x` / `c` / `d` / `m` | Cut / copy / delete / mark several files with a visual selection. | multiple many select visual range bulk move copy delete mark |
| `f` | Filter the tree by name as you type (live filter). `Esc` keeps it, `F` clears it. | filter search find narrow type name live |
| `S` | Search for a path and jump to it in the tree. | search find jump go to file folder path |
| `H` | Show / hide dotfiles (hidden files). | hidden dotfiles show toggle filter |
| `I` | Show / hide git-ignored files. | gitignore ignored hidden show toggle filter |
| `M` | Show only marked (bookmarked) files. | filter marked bookmark only show |
| `y` / `Y` / `gy` | Copy the file name / relative path / absolute path to the clipboard. | copy yank path name clipboard |
| `W` / `E` | Collapse all / expand all folders. | collapse expand close open all folders fold |
| `Ctrl + ]` / `-` | Make the folder under the cursor the root / go up one level. | cd root change directory parent up |
| `Ctrl + V` / `Ctrl + X` / `Ctrl + T` | Open the file in a vertical split / horizontal split / new tab. | open split vertical horizontal tab side |
| `s` | Open the file with the system app (xdg-open). | open external system default app xdg |

## 2. Reference

### Open

| Key Combination | Action | Search terms |
|---|---|---|
| `Enter` / `o` | Open the file, or expand / collapse the folder. | open edit expand |
| `Tab` | Preview the file (keeps the cursor in the tree). | open preview peek |
| `Ctrl + E` | Open the file in place of the tree window. | open replace |
| `O` | Open without the window picker. | open |
| `Ctrl + V` | Open in a vertical split. | open split side |
| `Ctrl + X` | Open in a horizontal split. | open split |
| `Ctrl + T` | Open in a new tab. | open tab |
| `s` | Open with the system default app. | open external xdg |
| `.` | Run a vim command on the file (`:` prefilled with its path). | run command |
| `q` | Close the tree. | close quit hide |

### File Operations

| Key Combination | Action | Search terms |
|---|---|---|
| `a` | Create a file (trailing `/` creates a folder). | new add create mkdir touch |
| `r` | Rename. | rename mv |
| `e` | Rename the basename only (keeps extension). | rename |
| `u` | Rename the full path (use this to move). | rename move mv path |
| `Ctrl + R` | Rename, starting with an empty name. | rename |
| `x` | Cut (mark for move). | cut move mv |
| `c` | Copy. | copy duplicate cp |
| `p` | Paste the cut / copied items into the folder under the cursor. | paste move copy |
| `d` / `Del` | Delete. | delete remove rm |
| `D` | Trash. | trash delete |

### Marks (Bookmarks) & Bulk Actions

| Key Combination | Action | Search terms |
|---|---|---|
| `m` | Mark / unmark the file or folder (works in visual mode too). | mark bookmark select toggle |
| `bmv` | Move all marked items to a folder (prompts for the path). | move mv bulk marked multiple |
| `bd` | Delete all marked items. | delete remove bulk marked multiple |
| `bt` | Trash all marked items. | trash bulk marked multiple |
| `M` | Show only marked items (toggle). | filter marked bookmark |

### Filters

| Key Combination | Action | Search terms |
|---|---|---|
| `f` | Start the live filter (type to narrow the tree). | filter search find live |
| `F` | Clear the live filter. | filter clear reset |
| `H` | Toggle dotfiles. | filter hidden dot |
| `I` | Toggle git-ignored files. | filter gitignore ignored |
| `C` | Show only files with git changes (toggle). | filter git changed modified dirty |
| `B` | Show only files open in a buffer (toggle). | filter buffers open |
| `U` | Toggle custom filters. | filter custom |

### Navigate

| Key Combination | Action | Search terms |
|---|---|---|
| `P` | Go to the parent folder. | parent up navigate |
| `Backspace` | Close the parent folder. | collapse close parent |
| `<` / `>` | Previous / next sibling. | sibling navigate |
| `K` / `J` | First / last sibling. | sibling first last navigate |
| `[c` / `]c` | Previous / next git-changed file. | git changes navigate next previous |
| `[e` / `]e` | Previous / next file with diagnostics. | diagnostics errors navigate |
| `S` | Search a path and jump to it. | search find jump |
| `W` | Collapse all. | collapse fold |
| `E` | Expand all. | expand unfold |
| `L` | Toggle grouping of empty folders. | group empty folders |
| `Ctrl + ]` | Make the folder under the cursor the root (cd). | cd root |
| `-` | Make the parent the root (up). | cd up root parent |
| `R` | Refresh the tree. | reload refresh |

### Info & Copy Path

| Key Combination | Action | Search terms |
|---|---|---|
| `Ctrl + K` | Show file info (size, modified date). | info details |
| `y` | Copy the file name. | yank copy name clipboard |
| `ge` | Copy the basename (no extension). | yank copy name clipboard |
| `Y` | Copy the relative path. | yank copy path clipboard |
| `gy` | Copy the absolute path. | yank copy path clipboard full |
| `g?` | Show the built-in help with all keys. | help keys mappings |
