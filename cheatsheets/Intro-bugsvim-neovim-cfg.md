# Intro to Bugsvim Neovim Config

This cheatsheet documents the Bugsvim Neovim setup used in ZaneyOS. It is defined in `modules/home/editors/bugsvim.nix` and the runtime config lives in `modules/home/editors/bugsvim-nvim/` (copied into `~/.config/nvim` during activation).

Highlights (what’s included)
- Lazy.nvim bootstrapping and plugin management
- LSP with diagnostics and helper keymaps
- Completion + snippets
- Treesitter highlighting, textobjects, incremental selection
- Formatting on save + manual formatting
- Linting on save
- Git signs, dashboards, pickers, file explorer, notifications
- DAP debugging (core + UI + Python adapter)
- Markdown tools (preview + checkbox/table helpers)

Where the config lives
- Nix entrypoint: `modules/home/editors/bugsvim.nix`
- Neovim config: `modules/home/editors/bugsvim-nvim/`

Enable diagnostics
- Diagnostics are configured in `lua/utils/diagnostics.lua` and enabled by default.
- Toggle diagnostics on/off with `<leader>ud` (Snacks toggle).
- Force-enable from command-line:
  ```vim path=null start=null
  :lua vim.diagnostic.enable()
  ```

LSP servers (enabled)
- lua_ls
- pyright
- ts_ls
- tailwindcss
- clangd
- bashls
- rust_analyzer
- html
- cssls
- nil_ls
- hyprls

Formatters (conform.nvim)
- lua: `stylua`
- python: `ruff_format`
- javascript/typescript/react: `prettierd`
- html/css/scss/json/jsonc/markdown/yaml: `prettierd`
- c/cpp: `clang-format`
- bash: `shfmt`
- nix: `alejandra`

Linters (nvim-lint)
- javascript/typescript: `eslint_d`
- lua: `luacheck`
- c/cpp: `cpplint`
- rust: `clippy`
- python: `ruff`

Keybinds (core)
- Centered search/motion:
  - `n` / `N` (next/prev search result centered)
  - `<C-d>` / `<C-u>` (half-page down/up centered)
- Buffer navigation:
  - `<leader>bn` / `<leader>bp`
  - `<Tab>` / `<S-Tab>`
- Window navigation: `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`
- Split windows:
  - `<leader>sv` (vsplit)
  - `<leader>sh` (split)
- Resize:
  - `<C-Up>`, `<C-Down>`, `<C-Left>`, `<C-Right>`
- Visual indenting: `<` / `>` (reselect)
- Join line, keep cursor: `J`
- Paste without yanking: `p` in visual
- Edit config: `<leader>rc`

Keybinds (LSP)
- Go to definition: `<leader>gd`
- Go to definition in split: `<leader>gS`
- Go to declaration: `<leader>gD`
- Code action: `<leader>ca`
- Rename: `<leader>rn`
- Diagnostics float: `<leader>D`
- Diagnostics under cursor: `<leader>cd`
- Prev/Next diagnostic: `<leader>[d` / `<leader>]d`
- Hover docs: `K`
- Organize imports (if supported): `<leader>oi`

Keybinds (formatting)
- Format buffer: `<leader>cf`

Keybinds (Markdown)
- Toggle checkbox: `<leader>mc`
- Preview: `<leader>mp`
- Preview toggle: `<leader>mt`
- Preview stop: `<leader>ms`

Keybinds (Git — Gitsigns)
- Next/Prev hunk: `]h` / `[h`
- First/Last hunk: `[H` / `]H`
- Stage/Reset hunk: `<leader>ghs` / `<leader>ghr` (normal/visual)
- Stage buffer: `<leader>ghS`
- Undo stage hunk: `<leader>ghu`
- Reset buffer: `<leader>ghR`
- Preview hunk: `<leader>ghp`
- Blame line/buffer: `<leader>ghb` / `<leader>ghB`
- Diff: `<leader>ghd` / `<leader>ghD`
- Toggle git signs: `<leader>uG`

Keybinds (Sessions — persistence.nvim)
- Restore session: `<leader>qs`
- Select session: `<leader>qS`
- Restore last session: `<leader>ql`
- Stop saving session: `<leader>qd`

Keybinds (Debug — nvim-dap)
- Toggle breakpoint: `<leader>dt`
- Start/Continue: `<leader>ds`
- Close UI: `<leader>dc`
- Step over/into/out: `<leader>dn` / `<leader>di` / `<leader>do`

Keybinds (Todos — todo-comments.nvim)
- Next/Prev todo: `]t` / `[t`
- Trouble todo list: `<leader>xt` / `<leader>xT`
- Telescope todo list: `<leader>st` / `<leader>sT`

Keybinds (Snacks)
- Smart file picker: `<leader><space>`
- Find files: `<leader>ff`
- Git files: `<leader>fg`
- Grep: `<leader>/` or `<leader>sg`
- Recent: `<leader>fr`
- File explorer: `<leader>e`
- Buffers: `<leader>,` or `<leader>fb`
- Diagnostics pickers: `<leader>sd` / `<leader>sD`
- LSP pickers: `gd`, `gD`, `gr`, `gI`, `gy`, `gai`, `gao`, `<leader>ss`, `<leader>sS`
- Toggle diagnostics: `<leader>ud`
- Toggle wrap: `<leader>uw`
- Toggle relativenumber: `<leader>uL`
- Toggle line numbers: `<leader>ul`
- Toggle treesitter: `<leader>uT`
- Toggle inlay hints: `<leader>uh`
- Toggle indent guides: `<leader>ug`
- Toggle zen/zoom: `<leader>z` / `<leader>Z`
- Scratch buffer: `<leader>.` / `<leader>S`
- Terminal: `<C-/>` (or `<C-_>`)

Treesitter textobjects and selection
- Incremental selection:
  - Start/expand: `<C-space>`
  - Expand scope: `<C-s>`
  - Shrink: `<M-space>`
- Textobjects:
  - Parameters: `aa` / `ia`
  - Functions: `af` / `if`
  - Classes: `ac` / `ic`
- Move between functions/classes:
  - Next start: `]m` / `]]`
  - Next end: `]M` / `][`
  - Prev start: `[m` / `[[`
  - Prev end: `[M` / `[]`
- Swap parameters:
  - Next: `<leader>a`
  - Prev: `<leader>A`

Plugins (what they do + how to use)

blink.cmp
- Features: completion UI, docs popup, LSP/path/snippet/buffer sources.
- Usage: enter insert mode; `<Tab>`/`<S-Tab>` navigate, `<CR>` accepts.

LuaSnip + friendly-snippets
- Features: snippet engine + curated snippet set.
- Usage: insert snippets via completion; expand with the completion accept key.

lazydev.nvim
- Features: faster/more accurate Lua LSP for Neovim config and Snacks types.
- Usage: automatically active for Lua buffers.

tokyonight.nvim
- Features: dark color scheme.
- Usage: loaded on startup (tokyonight-night).

conform.nvim
- Features: format on save + manual formatting.
- Usage: save the file, or run `<leader>cf` for manual format.

gitsigns.nvim
- Features: git change signs, hunk actions, blame, diff.
- Usage: see signs in gutter, use keymaps under “Keybinds (Git — Gitsigns)”.

lualine.nvim
- Features: statusline with mode, git, diagnostics, diff, file info.
- Usage: loads automatically; diagnostics show when window wide enough.

markdown-preview.nvim
- Features: live markdown preview in browser.
- Usage: `<leader>mp`, `<leader>mt`, `<leader>ms` or `:MarkdownPreview`.

markdown.nvim
- Features: markdown checkboxes and tables.
- Usage: toggle checkbox with `<leader>mc`.

mini.nvim modules
- Features:
  - mini.ai: textobject helpers
  - mini.comment: comment toggles
  - mini.move: move lines/blocks
  - mini.surround: add/delete/replace surroundings
  - mini.cursorword: highlight word under cursor
  - mini.pairs: auto-pairs
  - mini.trailspace: highlight trailing whitespace
  - mini.icons: filetype icons
- Usage: default module keymaps (check `:h mini-*`).

noice.nvim
- Features: improved commandline/notifications/LSP messages.
- Usage: automatic; improves UI for LSP hover and messages.

nvim-dap + nvim-dap-ui + nvim-dap-python
- Features: debugging core, UI panels, Python adapter.
- Usage: use debug keymaps; UI opens on start and closes on end.

nvim-lint
- Features: lint on save using configured linters.
- Usage: save file to lint.

nvim-lspconfig + mason.nvim
- Features: LSP setup, auto LSP install UI (mason).
- Usage: open a supported filetype; LSP attaches automatically.

nvim-treesitter + textobjects
- Features: syntax highlighting, indent, textobjects, incremental selection.
- Usage: automatic; see keymaps above.

persistence.nvim
- Features: session save/restore.
- Usage: use `<leader>q*` keymaps.

snacks.nvim
- Features: dashboard, picker, explorer, notifications, toggles, git helpers, terminal, zen mode.
- Usage: use leader keymaps under “Keybinds (Snacks)”.

todo-comments.nvim
- Features: highlight TODO/FIX/FIXME/BUG + navigation.
- Usage: `]t`/`[t`, `<leader>st`/`<leader>xt`.

which-key.nvim
- Features: popup help for keybindings.
- Usage: press `<leader>` or `<leader>?` for buffer-local.

