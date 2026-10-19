# Neovim Master Guide & Keymap Documentation

Welcome to your Neovim environment guide! This document is tailored directly to your configuration, explaining every custom key combination, general Neovim workflows, and how to use the interactive documentation lookup tool.

---

## ⚡ Instant Interactive Lookup (Never Read This Whole Doc Again!)

You have two fast ways to find keybindings and instructions instantly without scrolling through this document:

### 1. From Your Terminal: The `doc` Command
Whenever you are in your shell (bash, zsh, etc.), run:
```bash
# Launch interactive fuzzy finder with live preview:
doc

# Or directly search for a topic or keyword:
doc quick      # Shows how to open quickfix, loclist, and git hunk lists
doc doc        # Shows how to open LSP documentation and help tags
doc lsp        # Shows all LSP mappings (hover, definition, rename, etc.)
doc git        # Shows LazyGit, hunk staging, diffing, and blame
doc debug      # Shows IntelliJ-style debugging keys (F7, F8, F9, breakpoints)
doc java       # Shows Spring profiles, JDK picker, import organizer, and menu
doc terminal   # Shows floating terminal toggles (Ctrl+\, Ctrl+t, Alt+t)
```

### 2. From Inside Neovim: Press `<Space>?` or Run `:Doc`
- Press `<leader>?` (that is **`Space` then `?`** in Normal mode) or type `:Doc [query]`.
- An interactive Telescope window will pop up with live fuzzy search across all keybindings, categories, and instructions.
- As you type (e.g. `doc`, `quick`, `format`, `hunk`), the preview pane on the right immediately updates with the exact key combination, mode, and practical tips!

---

## 🧭 Neovim Core Concepts & Fundamentals

### The Modal Philosophy
Unlike regular text editors where typing always enters characters, Neovim operates in distinct **modes**:

| Mode | Entry Key | Description |
| :--- | :--- | :--- |
| **Normal** | `<Esc>` | Navigation, viewing, and executing editing commands. |
| **Insert** | `i` (before cursor), `a` (after cursor), `o` (new line below) | Typing raw text. |
| **Visual (Character)** | `v` | Selecting arbitrary character ranges. |
| **Visual Line** | `V` | Selecting whole lines. |
| **Visual Block** | `<C-v>` (Ctrl+v) | Selecting vertical rectangles / columns of text. |
| **Command** | `:` | Running Neovim commands (e.g. `:w`, `:q`, `:Doc`). |
| **Terminal** | `i` inside terminal | Interactive terminal input. Press `<Esc><Esc>` to return to Normal mode. |

### The Leader Key
Your leader key is mapped to **`<Space>`** (`vim.g.mapleader = ' '`).
Whenever you see `<leader>x`, it means:
1. Ensure you are in **Normal mode** (press `<Esc>`).
2. Tap **`Space`**, then tap **`x`**.
3. **Which-Key helper**: If you pause after pressing `Space`, an interactive hint window pops up showing every available next key!

### Movement: Why Arrow Keys Are Disabled!
In your configuration:
- The arrow keys (`<Up>`, `<Down>`, `<Left>`, `<Right>`) are intentionally configured to echo `"Use k to move!!"`, `"Use j to move!!"`, `"Use h to move!!"`, `"Use l to move!!"`.
- Keeping your fingers on the home row makes you dramatically faster:
  - `h`: Left
  - `j`: Down
  - `k`: Up
  - `l`: Right
  - `w`: Jump forward to the start of the next **w**ord
  - `b`: Jump **b**ackward to the start of the previous word
  - `e`: Jump to the **e**nd of the next word
  - `0`: Jump to the absolute beginning of the line
  - `^`: Jump to the first non-blank character on the line
  - `$`: Jump to the end of the line
  - `gg`: Jump to the top of the file
  - `G`: Jump to the bottom of the file
  - `<C-d>` / `<C-u>`: Scroll half-page **d**own / **u**p

### Verbs + Count + Nouns (Operators & Text Objects)
Vim commands compose like sentences:
- **Verbs (Operators)**:
  - `d`: Delete (cut)
  - `c`: Change (delete and switch to Insert mode)
  - `y`: Yank (copy)
  - `v`: Visually select
- **Nouns (Text Objects)**:
  - `iw`: **I**nner **w**ord (the word without surrounding spaces)
  - `aw`: **A** **w**ord (the word including surrounding space)
  - `i"` / `a"`: Inside / around double quotes
  - `i)` / `a)`: Inside / around parentheses
  - `i}` / `a}`: Inside / around curly braces
  - `ip`: Inside paragraph
- **Examples**:
  - `ciw`: **C**hange **i**nner **w**ord (deletes the current word and puts you in Insert mode)
  - `daw`: **D**elete **a** **w**ord (deletes the word and clean space around it)
  - `di"`: **D**elete everything inside `"quotes"`
  - `yap`: **Y**ank (copy) the entire current **p**aragraph
  - `3dd`: **D**elete **3** lines

### Clipboard & Pasting
- **OS Clipboard Sync**: `vim.o.clipboard = 'unnamedplus'`. Anything you yank (`y`) is automatically placed on your Arch Linux system clipboard, ready to paste into your browser or terminal!
- **Safe Visual Paste**: In normal Vim, pasting over highlighted text overwrites your clipboard. In your configuration, visual mode `p` is mapped to `"_dP`: you can paste over selected text repeatedly without losing what you copied!

---

## 📑 Complete Keymap Reference by Category

### 1. LSP (Language Server Protocol) & Documentation
LSP provides intelligent code navigation, autocomplete, and documentation:

| Key Combination | Mode | Action | Detailed Workflow & Tips |
| :--- | :--- | :--- | :--- |
| **`K`** | Normal | **Hover Documentation** | Press while on any symbol (function, class, variable). Shows full docstring, parameter types, and returns. **Tip:** Press `K` a second time to jump your cursor inside the doc float to scroll with `j`/`k`, then press `q` or `<Esc>` to exit. |
| **`grd`** | Normal | **Goto Definition** | Jumps to where the symbol was defined. Opens in Telescope if multiple definitions exist. **Press `<C-t>` to jump back to where you were!** |
| **`grr`** | Normal | **Goto References** | Opens Telescope showing all files and lines where this symbol is used. |
| **`gri`** | Normal | **Goto Implementation** | Jumps to the concrete implementation of an interface or abstract method. |
| **`grt`** | Normal | **Goto Type Definition** | Jumps to the definition of a variable's *type* rather than where it was instantiated. |
| **`grD`** | Normal | **Goto Declaration** | Jumps to declaration (e.g. C/C++ header declaration). |
| **`grn`** | Normal | **Rename Symbol** | Renames the symbol under cursor project-wide. Updates all occurrences safely. |
| **`gra`** | Normal, Visual | **Code Actions** | Opens available fixes, quick refactorings, or imports suggested by the LSP. |
| **`gO`** | Normal | **Document Symbols** | Telescope outline of all functions, classes, and variables in the current file. |
| **`gW`** | Normal | **Workspace Symbols** | Fuzzy search symbols across your entire project. |
| **`<leader>th`** | Normal | **Toggle Inlay Hints** | Toggles inline parameter name hints and inferred types in supported languages. |
| **`<leader>f`** | Normal, Visual | **Format Buffer / Selection** | Formats code asynchronously using `conform.nvim` (stylua, Java LSP, etc.). |

---

### 2. Diagnostics, Errors & Quickfix Window

| Key Combination | Mode | Action | Detailed Workflow & Tips |
| :--- | :--- | :--- | :--- |
| **`<leader>q`** | Normal | **Open Diagnostic Quickfix** | Populates and opens the location list with all compiler errors/warnings in current file. |
| **`]d`** | Normal | **Next Diagnostic** | Jumps to next error/warning and automatically displays floating explanation. |
| **`[d`** | Normal | **Previous Diagnostic** | Jumps to previous error/warning and displays floating explanation. |
| **`<leader>sd`** | Normal | **Search Diagnostics (Telescope)** | Search all diagnostics across the entire workspace in Telescope. |
| `:copen` / `:cclose` | Command | **Quickfix Open / Close** | Standard Neovim commands to open or dismiss the quickfix window. |
| `:cnext` / `:cprev` | Command | **Quickfix Next / Previous** | Step through items in the quickfix list (`:cn` and `:cp`). |

---

### 3. Autocompletion & Snippets (`blink.cmp` + `luasnip`)

| Key Combination | Mode | Action | Detailed Workflow & Tips |
| :--- | :--- | :--- | :--- |
| **`<C-Space>`** | Insert | **Trigger Completion & Docs** | Opens the autocomplete menu. If menu is already open, toggles the documentation preview panel for the highlighted item. |
| **`<C-y>`** | Insert | **Accept Completion** | Accepts item (`[y]es`). Automatically adds imports and expands snippet placeholders. |
| **`<C-n>` / `<Down>`** | Insert | **Next Suggestion** | Highlights next candidate in the popup. |
| **`<C-p>` / `<Up>`** | Insert | **Previous Suggestion** | Highlights previous candidate in the popup. |
| **`<C-e>`** | Insert | **Dismiss Menu** | Hides the completion popup without selecting. |
| **`<C-k>`** | Insert | **Signature Help** | Toggles floating parameter hints while typing function arguments. |
| **`<Tab>` / `<S-Tab>`** | Insert | **Snippet Placeholder Jump** | When a snippet is expanded, `<Tab>` jumps forward to the next placeholder; `<S-Tab>` jumps backward. |

---

### 4. Fuzzy Finding & Search (Telescope)

| Key Combination | Mode | Action | Detailed Workflow & Tips |
| :--- | :--- | :--- | :--- |
| **`<leader>sf`** | Normal | **Search Files** | Find files by name in current project (respects `.gitignore`). |
| **`<leader>SF`** | Normal | **Search All Files** | Find files including hidden (`.dotfiles`) and gitignored files. |
| **`<leader>sg`** | Normal | **Live Grep** | Search for text contents across all files via ripgrep in real time. |
| **`<leader>SG`** | Normal | **Live Grep All** | Search text across all files including hidden and gitignored files. |
| **`<leader>sw`** | Normal, Visual | **Search Word Under Cursor** | Greps for the word under cursor (or selected text) across the whole project. |
| **`<leader>/`** | Normal | **Fuzzy Search Current Buffer** | Interactive search within current file using a sleek dropdown preview. |
| **`<leader>s/`** | Normal | **Grep in Open Files** | Searches text across files you currently have open in buffers. |
| **`<leader><Space>`** | Normal | **Browse Open Buffers** | Fuzzy search and switch between currently open files. |
| **`<leader>s.`** | Normal | **Recent Files** | Search recently opened files (oldfiles history). |
| **`<leader>sk`** | Normal | **Search Keymaps** | Find any key combination configured in Neovim. |
| **`<leader>sh`** | Normal | **Search Help Tags** | Search Neovim's official documentation (`:help`). |
| **`<leader>sc`** | Normal | **Search Commands** | Search and run Neovim commands. |
| **`<leader>ss`** | Normal | **Select Builtin Pickers** | Browse all available Telescope pickers. |
| **`<leader>sr`** | Normal | **Resume Last Search** | Re-opens your previous Telescope search with the exact query preserved. |
| **`<leader>sn`** | Normal | **Search Neovim Config** | Fuzzy find files inside `~/.config/nvim`. |
| **`<leader>?`** | Normal | **Interactive Documentation** | Search this documentation and keybindings via Telescope! |
| **`<C-Enter>`** | Insert (Telescope) | **Fuzzy Refine** | Refine results within an active Telescope search. |
| **`<C-/>` or `?`** | Telescope | **Show Picker Keymaps** | Displays keys available inside the current Telescope picker. |

---

### 5. File Explorer & Window Splits

| Key Combination | Mode | Action | Detailed Workflow & Tips |
| :--- | :--- | :--- | :--- |
| **`\`** | Normal | **Toggle NvimTree** | Opens/closes NvimTree sidebar and automatically reveals and highlights the active file! |
| **`<C-h>`** | Normal | **Focus Left Window** | Move cursor to split on the left (`<C-w><C-h>`). |
| **`<C-j>`** | Normal | **Focus Lower Window** | Move cursor to split below (`<C-w><C-j>`). |
| **`<C-k>`** | Normal | **Focus Upper Window** | Move cursor to split above (`<C-w><C-k>`). |
| **`<C-l>`** | Normal | **Focus Right Window** | Move cursor to split on the right (`<C-w><C-l>`). |
| `<C-w>s` or `:split` | Normal | **Horizontal Split** | Splits current window horizontally. |
| `<C-w>v` or `:vsplit` | Normal | **Vertical Split** | Splits current window vertically. |
| `<C-w>q` or `:q` | Normal | **Close Split** | Closes active window. |

#### In NvimTree Explorer:
- `<CR>` or `o`: Open file or toggle directory
- `a`: Create new file (type name with `/` at the end to create directory)
- `d`: Delete file
- `r`: Rename file
- `R`: Refresh tree
- `q`: Close tree

---

### 6. Floating Terminals (ToggleTerm)

| Key Combination | Mode | Action | Detailed Workflow & Tips |
| :--- | :--- | :--- | :--- |
| **`<C-\>`** | Normal, Terminal | **Universal Float Terminal** | Toggle floating terminal with TokyoNight borders. Process stays alive when hidden. |
| **`<C-t>`** | Normal, Terminal | **Float Terminal #1** | Toggle persistent floating terminal session #1. |
| **`<M-t>`** (Alt+t) | Normal, Terminal | **Float Terminal #2** | Toggle independent persistent floating terminal session #2. |
| **`<Esc><Esc>`** | Terminal | **Exit Terminal Mode** | Switches terminal to Normal mode so you can scroll output or copy text. |

---

### 7. Git & Version Control (LazyGit & Gitsigns)

| Key Combination | Mode | Action | Detailed Workflow & Tips |
| :--- | :--- | :--- | :--- |
| **`<leader>gg`** | Normal | **LazyGit** | Opens full LazyGit TUI float. Selecting a file inside LazyGit opens it cleanly in Neovim! |
| **`<leader>gw`** | Normal | **Git Worktrees** | Jump to (or open) the kitty tab running Neovim in another worktree; the current one keeps running. Same as `o` in LazyGit's Worktrees panel. |
| **`]c` / `[c`** | Normal | **Next / Prev Git Hunk** | Jump cursor between changed blocks of code. |
| **`<leader>hs`** | Normal, Visual | **Stage Hunk** | Stage current hunk (or selected lines) into git index. |
| **`<leader>hr`** | Normal, Visual | **Reset Hunk** | Discard modifications in current hunk (or selected lines). |
| **`<leader>hS` / `<leader>hR`** | Normal | **Stage / Reset Buffer** | Stage or discard all modifications in the current file. |
| **`<leader>hp`** | Normal | **Preview Hunk** | Open floating diff window showing hunk changes. |
| **`<leader>hi`** | Normal | **Inline Hunk Diff** | Toggle inline diff view for current hunk. |
| **`<leader>hb`** | Normal | **Git Blame Line** | Detailed floating window showing commit message, author, and date for current line. |
| **`<leader>hd` / `<leader>hD`** | Normal | **Git Diff Split** | `<leader>hd` diffs against index; `<leader>hD` diffs against last commit (`@`). |
| **`<leader>hq` / `<leader>hQ`** | Normal | **Hunks to Quickfix** | `<leader>hq` loads changes in this file; `<leader>hQ` loads all repo changes into quickfix. |
| **`<leader>tb`** | Normal | **Toggle Blame** | Toggle virtual text inline blame at end of line. |
| **`<leader>tw`** | Normal | **Toggle Word Diff** | Highlight intra-line word changes inside hunks. |
| **`ih`** | Visual, Operator | **Hunk Text Object** | e.g. `dih` deletes current git hunk; `yih` yanks hunk. |

---

### 8. Debugger (DAP - IntelliJ IDEA Style)

Your debugger is mapped to feel like IntelliJ IDEA:

| Key Combination | Mode | Action | Detailed Workflow & Tips |
| :--- | :--- | :--- | :--- |
| **`<F9>` / `<F5>`** | Normal | **Resume / Start** | Start debugging or continue execution until next breakpoint (IntelliJ F9). |
| **`<F8>`** | Normal | **Step Over** | Step to next line without entering function calls (IntelliJ F8). |
| **`<F7>`** | Normal | **Step Into** | Step into the function call at cursor (IntelliJ F7). |
| **`<S-F8>`** (Shift+F8) | Normal | **Step Out** | Step out of current function to calling function (IntelliJ Shift+F8). |
| **`<A-F9>`** (Alt+F9) | Normal | **Run to Cursor** | Continue running directly until the line where your cursor is resting. |
| **`<C-F8>` / `<leader>b`** | Normal | **Toggle Breakpoint** | Toggle breakpoint on current line (IntelliJ Ctrl+F8 or `<Space>b`). |
| **`<leader>B`** | Normal | **Conditional Breakpoint** | Prompts for condition expression (e.g. `count == 50`). Only breaks when true. |
| **`<A-F8>` / `<leader>de`** | Normal | **Evaluate Expression** | Evaluate variable or expression under cursor in inspector float. |
| **`<leader>du`** | Normal | **Toggle Debug Panels** | Toggle DAP-UI panel (variables, stack, watches, breakpoints). |
| **`<leader>dc` / `:DapConsole`** | Normal | **Toggle Console Split** | Toggle bottom terminal showing program stdout/stderr. |
| **`<leader>dx` / `<leader>dl`** | Normal | **Clear / List Breakpoints** | `<leader>dx` clears all breakpoints; `<leader>dl` lists them. |

---

### 9. Java & Spring Boot Development (`nvim-jdtls` + `java.lua`)

| Key Combination | Mode | Action | Detailed Workflow & Tips |
| :--- | :--- | :--- | :--- |
| **`<leader>jj`** | Normal | **Java Action Menu** | Interactive menu: run main class, debug, run JUnit tests, Maven/Gradle build, logs. |
| **`<leader>jv` / `:JavaVersion`** | Normal | **JDK Picker** | Switch Java version (SDKMAN, system JVMs, IntelliJ JDKs). Persisted per-project. |
| **`<leader>jp` / `:SpringProfile`** | Normal | **Spring Profile** | Select active Spring Boot profile (`SPRING_PROFILES_ACTIVE`) for runs and tests. |
| **`<S-F10>`** (Shift+F10) | Normal | **Re-run Last App** | Incrementally compiles changed files and runs the last main class (IntelliJ Shift+F10). |
| **`<S-F9>`** (Shift+F9) | Normal | **Debug Main Class** | Start debug session for main class (IntelliJ Shift+F9). |
| **`<C-F2>`** (Ctrl+F2) | Normal | **Stop App** | Stop running application or debug session (IntelliJ Ctrl+F2). |
| **`<A-o>`** (Alt+o) | Normal | **Organize Imports** | Clean up, sort, and remove unused imports in Java file. |
| **`crv`** | Normal, Visual | **Extract Variable** | Refactor: extract expression into local variable. |
| **`crc`** | Normal, Visual | **Extract Constant** | Refactor: extract expression into `static final` constant. |
| **`crm`** | Visual | **Extract Method** | Refactor: extract highlighted lines into new method. |

---

### 10. Surround & Text Objects (`mini.surround` + `mini.ai`)

| Key Combination | Mode | Action | Example |
| :--- | :--- | :--- | :--- |
| **`saiw)`** | Normal | **Surround Add** | Surrounds current word with parentheses `(word)`. |
| **`sd'`** | Normal | **Surround Delete** | Deletes surrounding `'quotes'`. |
| **`sr)'`** | Normal | **Surround Replace** | Replaces surrounding `)` with `'`. |
| **`va)` / `vi)`** | Normal | **Visual Around / Inside** | Select around / inside parentheses. |
| **`yiiq`** | Normal | **Yank Inside Next Quote** | Copies text inside the next quote on the line. |
| **`ci'`** | Normal | **Change Inside Quote** | Deletes inside `'quotes'` and enters Insert mode. |

---

## 💡 Quick Cheat-Sheet Summary

| When You Want To... | Press This: |
| :--- | :--- |
| **Look up documentation / help interactively** | `doc <topic>` (terminal) or `<Space>?` (Neovim) |
| **View LSP function docs / type signatures** | `K` (Normal mode) |
| **Jump to code definition** | `grd` (jump back with `<C-t>`) |
| **Find all references across project** | `grr` |
| **Open compiler / diagnostic errors quickfix** | `<Space>q` |
| **Jump to next / previous error** | `]d` and `[d` |
| **Search files in project** | `<Space>sf` (or `<Space>SF` for all files) |
| **Search text inside all files (grep)** | `<Space>sg` |
| **Format code buffer** | `<Space>f` |
| **Rename variable project-wide** | `grn` |
| **Open code actions / fixes** | `gra` |
| **Toggle file tree (NvimTree)** | `\` |
| **Open terminal** | `<C-\>` or `<C-t>` |
| **Open LazyGit** | `<Space>gg` |
| **Jump to next git change** | `]c` (or `[c` for previous) |
| **Stage / reset git change** | `<Space>hs` (stage) / `<Space>hr` (reset) |
| **Debug: Step over / into / resume** | `<F8>` (over), `<F7>` (into), `<F9>` (resume) |
| **Toggle breakpoint** | `<C-F8>` or `<Space>b` |
| **Java menu / run / test** | `<Space>jj` |
