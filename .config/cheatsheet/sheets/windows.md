# Windows Management

## 1. Create Windows (Splits)

| Key Combination | Action |
|---|---|
| `Ctrl + W`, then `V` | Create a vertical split (side by side). |
| `Ctrl + W`, then `S` | Create a horizontal split (top and bottom). |
| `Ctrl + W`, then `N` | Create a new empty horizontal split. |

## 2. Navigate Between Windows

| Key Combination | Action |
|---|---|
| `Ctrl + H` | Move focus to the left window. |
| `Ctrl + L` | Move focus to the right window. |
| `Ctrl + K` | Move focus to the upper window. |
| `Ctrl + J` | Move focus to the lower window. |

## 3. Resize Windows

| Key Combination | Action |
|---|---|
| `Ctrl + W`, then `=` | Equalize the sizes of all windows. |
| `Ctrl + W`, then `_` | Maximize the current window's height. |
| `Ctrl + W`, then `|` | Maximize the current window's width. |
| `Ctrl + W`, then `>` | Increase the current window's width. |
| `Ctrl + W`, then `<` | Decrease the current window's width. |
| `Ctrl + W`, then `+` | Increase the current window's height. |
| `Ctrl + W`, then `-` | Decrease the current window's height. |

## 4. Rearrange Windows

| Key Combination | Action |
|---|---|
| `Ctrl + W`, then `R` | Rotate window positions clockwise. |
| `Ctrl + W`, then `Shift + R` | Rotate window positions counterclockwise. |
| `Ctrl + W`, then `X` | Exchange the current window with the next window. |
| `Ctrl + W`, then `Shift + H` | Move the current window to the far left. |
| `Ctrl + W`, then `Shift + L` | Move the current window to the far right. |
| `Ctrl + W`, then `Shift + K` | Move the current window to the top. |
| `Ctrl + W`, then `Shift + J` | Move the current window to the bottom. |
| `Ctrl + W`, then `Shift + T` | Move the current window into a new tab. |

## 5. Close Windows

| Key Combination | Action |
|---|---|
| `Ctrl + W`, then `Q` | Close the current window. |
| `Ctrl + W`, then `O` | Close all other windows, keeping the current one open. |

## 6. Open Files in Splits

### File Explorer (Neo-tree)

| Key Combination | Action |
|---|---|
| `Enter` | Open the selected file in the current window. |
| `O` | Open the selected file in the current window. |
| `Ctrl + V` | Open the selected file in a vertical split. |
| `Ctrl + X` | Open the selected file in a horizontal split. |
| `Ctrl + T` | Open the selected file in a new tab. |

### Telescope (File Search)

| Key Combination | Action |
|---|---|
| `Enter` | Open the selected file in the current window. |
| `Ctrl + V` | Open the selected file in a vertical split. |
| `Ctrl + X` | Open the selected file in a horizontal split. |
| `Ctrl + T` | Open the selected file in a new tab. |

## 7. Manage Tabs

| Key Combination | Action |
|---|---|
| `gt` | Switch to the next tab. |
| `gT` | Switch to the previous tab. |
| `1gt` | Switch to tab 1. |
| `2gt` | Switch to tab 2. |
| `3gt` | Switch to tab 3. |

### Tab Commands

| Command | Action |
|---|---|
| `:tabnew` | Create a new tab. |
| `:tabedit filename` | Open a file in a new tab. |
| `:tabmove -1` | Move the current tab one position to the left. |
| `:tabmove +1` | Move the current tab one position to the right. |
| `:tabmove 0` | Move the current tab to the beginning. |
| `:tabmove` | Move the current tab to the end. |
| `:tabclose` | Close the current tab. |
| `:tabonly` | Close all other tabs. |

## 8. Manage Terminal Windows

| Command / Key Combination | Action |
|---|---|
| `Ctrl + \` | Toggle the configured terminal. |
| `Ctrl + T` | Toggle the configured terminal. |
| `Alt + T` | Toggle the configured terminal. |
| `:ToggleTerm direction=horizontal` | Open a terminal in a horizontal split. |
| `:ToggleTerm direction=vertical` | Open a terminal in a vertical split. |
| `:split \| terminal` | Open a built-in terminal in a horizontal split. |
| `:vsplit \| terminal` | Open a built-in terminal in a vertical split. |
| `Esc`, then `Esc` | Exit terminal mode. |
