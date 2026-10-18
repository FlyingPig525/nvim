-- Set <space> as the leader key
-- See `:h mapleader`
-- NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "

-- OPTIONS
--
-- See `:h vim.o`
-- NOTE: You can change these options as you wish!
-- For more options, you can see `:h option-list`
-- To see documentation for an option, you can use `:h 'optionname'`, for example `:h 'number'`
-- (Note the single quotes)

vim.o.number = true -- Show line numbers in a column.

-- Show line numbers relative to where the cursor is.
-- Affects the 'number' option above, see `:h number_relativenumber`.
vim.o.relativenumber = true

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.wrap = false

vim.o.hlsearch = false
vim.o.incsearch = true

vim.o.termguicolors = true

vim.o.updatetime = 50
-- Sync clipboard between OS and Neovim. Schedule the setting after `UIEnter` because it can
-- increase startup-time. Remove this option if you want your OS clipboard to remain independent.
-- See `:h 'clipboard'`
vim.api.nvim_create_autocmd("UIEnter", {
    callback = function()
        vim.o.clipboard = "unnamedplus"
    end,
})

local function gh(repo)
    return "https://github.com/" .. repo
end

vim.api.nvim_create_user_command("ES", "e ~/.config/nvim/init.lua", {})
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.cursorline = true -- Highlight the line where the cursor is on.
vim.o.scrolloff = 15 -- Keep this many screen lines above/below the cursor.
vim.o.list = true -- Show <tab> and trailing spaces.

-- If performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s). See `:h 'confirm'`
vim.o.confirm = true

vim.o.autocomplete = false
-- KEYMAPS
--
-- See `:h vim.keymap.set()`, `:h mapping`, `:h keycodes`

-- Use <Esc> to exit terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

-- Map <A-j>, <A-k>, <A-h>, <A-l> to navigate between windows in any modes
vim.keymap.set({ "t", "i" }, "<A-h>", "<C-\\><C-n><C-w>h")
vim.keymap.set({ "t", "i" }, "<A-j>", "<C-\\><C-n><C-w>j")
vim.keymap.set({ "t", "i" }, "<A-k>", "<C-\\><C-n><C-w>k")
vim.keymap.set({ "t", "i" }, "<A-l>", "<C-\\><C-n><C-w>l")
vim.keymap.set({ "n" }, "<A-h>", "<C-w>h")
vim.keymap.set({ "n" }, "<A-j>", "<C-w>j")
vim.keymap.set({ "n" }, "<A-k>", "<C-w>k")
vim.keymap.set({ "n" }, "<A-l>", "<C-w>l")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set("n", "<C-h>", "<C-w><C-h>")
vim.keymap.set("n", "<C-l>", "<C-w><C-l>")
vim.keymap.set("n", "<C-j>", "<C-w><C-j>")
vim.keymap.set("n", "<C-k>", "<C-w><C-k>")

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)

vim.pack.add({ gh("folke/snacks.nvim") })
local bufdelete = require("snacks.bufdelete")

vim.keymap.set("n", "<leader>bd", bufdelete.delete)
vim.keymap.set("n", "<leader>bi", bufdelete.invisible)
vim.keymap.set("n", "<leader>bo", bufdelete.other)
vim.keymap.set("n", "<leader>ba", bufdelete.all)

do
    -- [[ Intro to `vim.pack` ]]
    -- `vim.pack` is a new plugin manager built into Neovim,
    --  which provides a Lua interface for installing and managing plugins.
    --
    --  See `:help vim.pack`, `:help vim.pack-examples` or the
    --  excellent blog post from the creator of vim.pack and mini.nvim:
    --  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
    --
    --  To inspect plugin state and pending updates, run
    --    :lua vim.pack.update(nil, { offline = true })
    --
    --  To update plugins, run
    --    :lua vim.pack.update()
    --
    --
    --  Throughout the rest of the config there will be examples
    --  of how to install and configure plugins using `vim.pack`.
    --
    --  In this section we set up some autocommands to run build
    --  steps for certain plugins after they are installed or updated.

    local function run_build(name, cmd, cwd)
        local result = vim.system(cmd, { cwd = cwd }):wait()
        if result.code ~= 0 then
            local stderr = result.stderr or ""
            local stdout = result.stdout or ""
            local output = stderr ~= "" and stderr or stdout
            if output == "" then
                output = "No output from build command."
            end
            vim.notify(("Build failed for %s:\n%s"):format(name, output), vim.log.levels.ERROR)
        end
    end

    -- This autocommand runs after a plugin is installed or updated and
    --  runs the appropriate build command for that plugin if necessary.
    --
    -- See `:help vim.pack-events`
    vim.api.nvim_create_autocmd("PackChanged", {
        callback = function(ev)
            local name = ev.data.spec.name
            local kind = ev.data.kind
            if kind ~= "install" and kind ~= "update" then
                return
            end

            if name == "telescope-fzf-native.nvim" and vim.fn.executable("make") == 1 then
                run_build(name, { "make" }, ev.data.path)
                return
            end

            if name == "LuaSnip" then
                if vim.fn.has("win32") ~= 1 and vim.fn.executable("make") == 1 then
                    run_build(name, { "make", "install_jsregexp" }, ev.data.path)
                end
                return
            end

            if name == "nvim-treesitter" then
                if not ev.data.active then
                    vim.cmd.packadd("nvim-treesitter")
                end
                vim.cmd("TSUpdate")
                return
            end
        end,
    })
end
-- AUTOCOMMANDS (EVENT HANDLERS)
--
-- See `:h lua-guide-autocommands`, `:h autocmd`, `:h nvim_create_autocmd()`

-- Highlight when yanking (copying) text.
-- Try it with `yap` in normal mode. See `:h vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    callback = function()
        vim.hl.on_yank()
    end,
})
vim.pack.add({
    "https://github.com/nvim-lua/plenary.nvim",
    gh("nvim-telescope/telescope-file-browser.nvim"),
    "https://github.com/ibhagwan/fzf-lua",
    gh "nvim-telescope/telescope-fzf-native.nvim",
    gh "nvim-telescope/telescope.nvim"
})
require("plenary")
require("fzf-lua").setup({ fzf_colors = true })
local res, other = pcall(require("telescope").setup, {})
if res then
    require("telescope").load_extension("file_browser")
    require("telescope").load_extension("fzf")
    vim.keymap.set("n", "<leader>fs", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")
    -- See `:help telescope.builtin`
    local builtin = require("telescope.builtin")
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
        callback = function(event)
            local buf = event.buf

            -- Find references for the word under your cursor.
            vim.keymap.set("n", "grr", builtin.lsp_references, { buffer = buf, desc = "[G]oto [R]eferences" })

            -- Jump to the implementation of the word under your cursor.
            -- Useful when your language has ways of declaring types without an actual implementation.
            vim.keymap.set("n", "gri", builtin.lsp_implementations, { buffer = buf, desc = "[G]oto [I]mplementation" })

            -- Jump to the definition of the word under your cursor.
            -- This is where a variable was first declared, or where a function is defined, etc.
            -- To jump back, press <C-t>.
            vim.keymap.set("n", "grd", builtin.lsp_definitions, { buffer = buf, desc = "[G]oto [D]efinition" })

            -- Fuzzy find all the symbols in your current document.
            -- Symbols are things like variables, functions, types, etc.
            vim.keymap.set("n", "gO", builtin.lsp_document_symbols, { buffer = buf, desc = "Open Document Symbols" })

            -- Fuzzy find all the symbols in your current workspace.
            -- Similar to document symbols, except searches over your entire project.
            vim.keymap.set(
                "n",
                "gW",
                builtin.lsp_dynamic_workspace_symbols,
                { buffer = buf, desc = "Open Workspace Symbols" }
            )

            -- Jump to the type of the word under your cursor.
            -- Useful when you're not sure what type a variable is and you want to see
            -- the definition of its *type*, not where it was *defined*.
            vim.keymap.set(
                "n",
                "grt",
                builtin.lsp_type_definitions,
                { buffer = buf, desc = "[G]oto [T]ype Definition" }
            )
        end,
    })
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
else
    print(res, other)
end
vim.pack.add({ gh("j-hui/fidget.nvim") })
require("fidget").setup({})

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
    callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map("grn", vim.lsp.buf.rename, "[R]e[n]ame")

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method("textDocument/documentHighlight", event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                callback = function(event2)
                    vim.lsp.buf.clear_references()
                    vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
                end,
            })
        end
    end,
})

do
    -- [[ Formatting ]]
    vim.pack.add({ gh("stevearc/conform.nvim") })
    require("conform").setup({
        notify_on_error = false,
        format_on_save = function(bufnr)
            -- You can specify filetypes to autoformat on save here:
            local enabled_filetypes = {
                -- lua = true,
                -- python = true,
            }
            if enabled_filetypes[vim.bo[bufnr].filetype] then
                return { timeout_ms = 500 }
            else
                return nil
            end
        end,
        default_format_opts = {
            lsp_format = "fallback", -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
        },
        -- You can also specify external formatters in here.
        formatters_by_ft = {
            -- rust = { 'rustfmt' },
            -- Conform can also run multiple formatters sequentially
            -- python = { "isort", "black" },
            --
            -- You can use 'stop_after_first' to run the first available formatter from the list
            -- javascript = { "prettierd", "prettier", stop_after_first = true },
        },
    })

    vim.keymap.set({ "n", "v" }, "<leader>f", function()
        require("conform").format({ async = true })
    end, { desc = "[F]ormat buffer" })
end
-- USER COMMANDS: DEFINE CUSTOM COMMANDS
--
-- See `:h nvim_create_user_command()` and `:h user-commands`

-- Create a command `:GitBlameLine` that print the git blame for the current line
vim.api.nvim_create_user_command("GitBlameLine", function()
    local line_number = vim.fn.line(".") -- Get the current line number. See `:h line()`
    local filename = vim.api.nvim_buf_get_name(0)
    print(vim.system({ "git", "blame", "-L", line_number .. ",+1", filename }):wait().stdout)
end, { desc = "Print the git blame for the current line" })

-- PLUGINS
--
-- See `:h :packadd`, `:h vim.pack`

-- Add the "nohlsearch" package to automatically disable search highlighting after
-- 'updatetime' and when going to insert mode.

-- Install third-party plugins via "vim.pack.add()".
vim.pack.add({
    -- Quickstart configs for LSP
    "https://github.com/neovim/nvim-lspconfig",
    -- Fuzzy picker
    -- Autocompletion
    -- Enhanced quickfix/loclist
    "https://github.com/stevearc/quicker.nvim",
    -- Git integration
    "https://github.com/lewis6991/gitsigns.nvim",
    "https://github.com/nvim-tree/nvim-web-devicons",
    "https://github.com/navarasu/onedark.nvim",
    -- i kind of like these colorschemes, but i like onedark more
    -- gh "EdenEast/nightfox.nvim",
    gh("wakatime/vim-wakatime"),
    gh("nvim-treesitter/nvim-treesitter-context"),
})

require("nvim-web-devicons").setup({})
require("quicker").setup({})
require("gitsigns").setup({})
require("onedark").setup({
    style = "darker",
})
require("onedark").load()
require("wakatime").setup()
require("treesitter-context").setup()
vim.keymap.set("n", "<C-c>", function()
    require("treesitter-context").go_to_context(vim.v.count1)
end)
-- LSP --
-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--  See `:help lsp-config` for information about keys and how to configure
---@type table<string, vim.lsp.Config>
local servers = {
    -- clangd = {},
    -- gopls = {},
    -- pyright = {},
    -- rust_analyzer = {},
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`ts_ls`) will work just fine
    -- ts_ls = {},

    stylua = {}, -- Used to format Lua code
    zls = {
        -- Command and arguments to start the server.
        cmd = { "zls" },
        -- Filetypes to automatically attach to.
        filetypes = { "zig" },
        -- Sets the "workspace" to the directory where any of these files is found.
        -- Files that share a root directory will reuse the LSP server connection.
        -- Nested lists indicate equal priority, see |vim.lsp.Config|.
        root_markers = { { "build.zig", "build.zig.zon" }, ".git" },
        -- Specific settings to send to the server. The schema is server-defined.
        -- Example: https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
        settings = {},
    },
    --    kotlin_lsp = {
    --        cmd = { "kotlin-lsp", "--socket", "8883" },
    --        filetypes = { "kotlin" },
    --        root_markers = { { ".kotlin", "build.gradle.kts", "build.gradle", "settings.gradle.kts" }, ".git" },
    --    },
    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
        on_init = function(client)
            client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

            if client.workspace_folders then
                local path = client.workspace_folders[1].name
                if
                    path ~= vim.fn.stdpath("config")
                    and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
                then
                    return
                end
            end

            local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
            client.config.settings.Lua = vim.tbl_deep_extend("force", current_settings.Lua, {
                runtime = {
                    version = "LuaJIT",
                    path = { "lua/?.lua", "lua/?/init.lua" },
                },
                workspace = {
                    checkThirdParty = false,
                    -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
                    --  See https://github.com/neovim/nvim-lspconfig/issues/3189
                    library = vim.api.nvim_get_runtime_file("", true),
                },
            })
        end,
        ---@type lspconfig.settings.lua_ls
        settings = {
            Lua = {
                format = { enable = false }, -- Disable formatting (formatting is done by stylua)
            },
        },
    },
    kotlin_lsp = {
        cmd = { "kotlin-lsp", "--stdio" },
        single_file_support = true,
        filetypes = { "kotlin" },
        root_markers = { { "build.gradle", "build.gradle.kts", "pom.xml" }, ".git" },
    },
}

vim.pack.add({
    gh("neovim/nvim-lspconfig"),
    gh("mason-org/mason.nvim"),
    gh("mason-org/mason-lspconfig.nvim"),
    gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
})

-- Automatically install LSPs and related tools to stdpath for Neovim
require("mason").setup({})

-- Translates between nvim-lspconfig server names and mason.nvim package names (e.g. lua_ls <-> lua-language-server)
require("mason-lspconfig").setup({
    automatic_enable = true, -- Change this to true if you want to automatically enable servers that are installed manually (e.g. via :Mason / :MasonInstall)
})

-- Ensure the servers and tools above are installed
--
-- To check the current status of installed tools and/or manually install
-- other tools, you can run
--    :Mason
--
-- You can press `g?` for help in this menu.
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
    -- You can add other tools here that you want Mason to install
})

require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
end

vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled())

local function a()
    -- [[ Snippet Engine ]]

    -- NOTE: You can also specify plugin using a version range for its git tag.
    --  See `:help vim.version.range()` for more info
    vim.pack.add({ { src = gh("L3MON4D3/LuaSnip"), version = vim.version.range("2.*") } })
    require("luasnip").setup({})

    -- `friendly-snippets` contains a variety of premade snippets.
    --    See the README about individual language/framework/plugin snippets:
    --    https://github.com/rafamadriz/friendly-snippets
    --
    -- vim.pack.add { gh 'rafamadriz/friendly-snippets' }
    -- require('luasnip.loaders.from_vscode').lazy_load()

    -- [[ Autocomplete Engine ]]
    vim.pack.add({ { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") } })
    require("blink.cmp").setup({
        keymap = {
            -- 'default' (recommended) for mappings similar to built-in completions
            --   <c-y> to accept ([y]es) the completion.
            --    This will auto-import if your LSP supports it.
            --    This will expand snippets if the LSP sent a snippet.
            -- 'super-tab' for tab to accept
            -- 'enter' for enter to accept
            -- 'none' for no mappings
            --
            -- For an understanding of why the 'default' preset is recommended,
            -- you will need to read `:help ins-completion`
            --
            -- No, but seriously. Please read `:help ins-completion`, it is really good!
            --
            -- All presets have the following mappings:
            -- <tab>/<s-tab>: move to right/left of your snippet expansion
            -- <c-space>: Open menu or open docs if already open
            -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
            -- <c-e>: Hide menu
            -- <c-k>: Toggle signature help
            --
            -- See `:help blink-cmp-config-keymap` for defining your own keymap
            -- preset = 'enter',

            ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-e>"] = { "hide", "fallback" },
            ["<CR>"] = { "accept", "fallback" },
            ["<C-CR>"] = { "snippet_forward" },

            ["<Tab>"] = { "select_next", "fallback" },
            ["<S-Tab>"] = { "select_prev", "fallback" },

            ["<Up>"] = { "select_prev", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
            ["<C-n>"] = { "select_next", "fallback_to_mappings" },

            ["<C-b>"] = { "scroll_documentation_up", "fallback" },
            ["<C-f>"] = { "scroll_documentation_down", "fallback" },

            ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
            -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
            --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
        },

        appearance = {
            -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
            -- Adjusts spacing to ensure icons are aligned
            nerd_font_variant = "mono",
        },

        completion = {
            -- By default, you may press `<c-space>` to show the documentation.
            -- Optionally, set `auto_show = true` to show the documentation after a delay.
            documentation = { auto_show = true, auto_show_delay_ms = 500 },
            -- list = {
            -- selection = { preselect = false, auto_insert = false },
            -- },
        },

        sources = {
            default = { "lsp", "path", "snippets" },
        },

        snippets = { preset = "luasnip" },

        -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
        -- which automatically downloads a prebuilt binary when enabled.
        --
        -- By default, we use the Lua implementation instead, but you may enable
        -- the rust implementation via `'prefer_rust_with_warning'`
        --
        -- See `:help blink-cmp-config-fuzzy` for more information
        --fuzzy = { implementation = 'lua' },

        -- Shows a signature help window while you type arguments for a function
        signature = { enabled = true },
    })
end
a()
vim.pack.add({ gh("nvim-mini/mini.nvim") })
require("mini.comment").setup()
if vim.g.have_nerd_font then
    require("mini.icons").setup()
    MiniIcons.mock_nvim_web_devicons()
end
-- Better Around/Inside textobjects
--
-- Examples:
--  - va)  - [V]isually select [A]round [)]paren
--  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
--  - ci'  - [C]hange [I]nside [']quote
require("mini.ai").setup({
    -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
    mappings = {
        around_next = "aa",
        inside_next = "ii",
    },
    n_lines = 500,
})

-- Add/delete/replace surroundings (brackets, quotes, etc.)
-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
-- - sd'   - [S]urround [D]elete [']quotes
-- - sr)'  - [S]urround [R]eplace [)] [']
require("mini.surround").setup()

-- Simple and easy statusline.
--  You could remove this setup call if you don't like it,
--  and try some other statusline plugin
local MiniStatusline = require("mini.statusline")
-- Set `use_icons` to true if you have a Nerd Font
local function content()
    local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
    local git = MiniStatusline.section_git({ trunc_width = 40 })
    local diff = MiniStatusline.section_diff({ trunc_width = 75 })
    local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
    local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
    local filename = MiniStatusline.section_filename({ trunc_width = 140 })
    local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
    local location = MiniStatusline.section_location({ trunc_width = 75 })
    local search = MiniStatusline.section_searchcount({ trunc_width = 75 })
    local time = require("wakatime").statusline()

    return MiniStatusline.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = "WakatimeTime", strings = { time } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
        "%<", -- Mark general truncate point
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=", -- End left alignment
        { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
        { hl = mode_hl, strings = { search, location } },
    })
end
MiniStatusline.setup({
    use_icons = vim.g.have_nerd_font,
    content = {
        active = content,
    },
})
vim.api.nvim_set_hl(0, "WakatimeTime", { bg = "#A584FF", fg = "#1F2329" })
-- You can configure sections in the statusline by overriding their
-- default behavior. For example, here we set the section for
-- cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
MiniStatusline.section_location = function()
    return "%2l:%-2v"
end


-- ============================================================
-- SECTION 9: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
    -- [[ Configure Treesitter ]]
    --  Used to highlight, edit, and navigate code
    --
    --  See `:help nvim-treesitter-intro`

    -- NOTE: You can also specify a branch or a specific commit
    vim.pack.add({ { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" } })

    -- Ensure basic parsers are installed
    local parsers =
        { "bash", "c", "diff", "html", "lua", "luadoc", "markdown", "markdown_inline", "query", "vim", "vimdoc" }
    require("nvim-treesitter").install(parsers)

    ---@param buf integer
    ---@param language string
    local function treesitter_try_attach(buf, language)
        -- Check if a parser exists and load it
        if not vim.treesitter.language.add(language) then
            return
        end
        -- Enable syntax highlighting and other treesitter features
        vim.treesitter.start(buf, language)

        -- Enable treesitter based folds
        -- For more info on folds see `:help folds`
        -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        -- vim.wo.foldmethod = 'expr'

        -- Check if treesitter indentation is available for this language, and if so enable it
        -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
        local has_indent_query = vim.treesitter.query.get(language, "indents") ~= nil

        -- Enable treesitter based indentation
        if has_indent_query then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end

    local available_parsers = require("nvim-treesitter").get_available()
    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
            local buf, filetype = args.buf, args.match

            local language = vim.treesitter.language.get_lang(filetype)
            if not language then
                return
            end

            local installed_parsers = require("nvim-treesitter").get_installed("parsers")

            if vim.tbl_contains(installed_parsers, language) then
                -- Enable the parser if it is already installed
                treesitter_try_attach(buf, language)
            elseif vim.tbl_contains(available_parsers, language) then
                -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
                require("nvim-treesitter").install(language):await(function()
                    treesitter_try_attach(buf, language)
                end)
            else
                -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
                treesitter_try_attach(buf, language)
            end
        end,
    })
end
