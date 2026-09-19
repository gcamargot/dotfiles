-- Y yank until the end of line  (note: this is now a default on master)
vim.keymap.set("n", "Y", "y$", { noremap = true })
-- Re-center on next term
vim.keymap.set("n", "n", "nzz", { noremap = true })
vim.keymap.set("n", "N", "Nzz", { noremap = true })

local function cmd(text, lua)
	if lua then
		return ":lua " .. text .. "<CR>"
	else
		return "<Cmd>" .. text .. "<CR>"
	end
end

local function key_binding(key, command, description, mode, lua)
	if mode == nil then
		mode = "n"
	end
	vim.keymap.set(mode, "<leader>" .. key, cmd(command, lua), { desc = description })
end

local key_menu_ok, key_menu = pcall(require, "key-menu")
if key_menu_ok then
	key_menu.set("n", "<Space>")
end

-- Fundamentals
key_binding("n", "noh", "Clear highlights")
key_binding("q", "wqa", "Quit")
key_binding("Q", "qa!", "Quit without saving")

-- Git
--key_binding("g", "Neogit kind=floating", "Neogit")
key_binding("g", "Neogit", "Neogit")

-- LSP bindings
if key_menu_ok then
	key_menu.set("n", "<Space>l", { desc = "LSP" })
end
key_binding("lr", "vim.lsp.buf.rename()", "Rename", nil, true)
key_binding("lR", "vim.lsp.buf.references()", "Find References", nil, true)
key_binding("ld", "vim.lsp.buf.definition()", "Go to Definition", nil, true)
key_binding("la", "vim.lsp.buf.code_action()", "Code Action", nil, true)
key_binding("le", "vim.lsp.diagnostic.get_line_diagnostics()", "Diagnostics", nil, true)

-- Telescope
if key_menu_ok then
	key_menu.set("n", "<Space>t", { desc = " Telescope" })
end
key_binding("tf", "Telescope find_files", "󰈔 Find Files")
key_binding("tg", "Telescope live_grep", "󰈭 Grep")
key_binding("tp", "Telescope projects", "Switch project")
key_binding("tS", "require('telescope.builtin').live_grep({cwd = '~/Documents'})", "Search all projects", nil, true)
key_binding("td", "Telescope diagnostics", "Diagnostics")
key_binding("tr", "Telescope oldfiles", "Recent files")
key_binding("tb", "Telescope buffers", "Open buffers")
key_binding("tc", "Telescope command_history", "Command History")
key_binding("yq", "require('nahtao97.telescope').yq_search()", "󰈭 YAML Query (yq)", nil, true)

-- Trouble
key_binding("Td", "Trouble diagnostics", "Diagnostics")
key_binding("Tt", "Trouble todo", "TO-DO comments")

-- Aerial
key_binding("a", "AerialOpen", "Aerial menu")

-- Oil
key_binding("o", "Oil", "Edit files (oil)")

-- Tasks
key_binding("rt", "TaskRunner", "Run task")

-- Recent work
key_binding("rw", "RecentWorkMyCommits", "Recent work")

-- Tabs
-- vim.api.nvim_set_keymap("n", "<leader>ta", ":$tabnew<CR>", { noremap = true })
key_binding("tta", ":$tabnew<CR>", "New Tab")

-- LuaSnip
if key_menu_ok then
	key_menu.set("n", "<Space>s", { desc = "Snippets" })
end
key_binding("sr", "source ~/.config/nvim/after/plugin/luasnip.lua", "Reload")

-- Terminal Integrado
key_binding("T", "botright 12split | terminal", "Abrir Terminal abajo")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Salir a modo normal en terminal" })
vim.keymap.set("t", "<C-w>k", "<C-\\><C-n><C-w>k", { desc = "Ir a ventana de arriba" })
vim.keymap.set("t", "<C-w>j", "<C-\\><C-n><C-w>j", { desc = "Ir a ventana de abajo" })
vim.keymap.set("t", "<C-w>h", "<C-\\><C-n><C-w>h", { desc = "Ir a ventana izquierda" })
vim.keymap.set("t", "<C-w>l", "<C-\\><C-n><C-w>l", { desc = "Ir a ventana derecha" })

-- Mover bloques seleccionados arriba/abajo con auto-indentación
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Mover bloque abajo y auto-identar", silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Mover bloque arriba y auto-identar", silent = true })

-- Mantener la selección al identar en modo visual
vim.keymap.set("v", "<", "<gv", { desc = "Desidentar manteniendo selección" })
vim.keymap.set("v", ">", ">gv", { desc = "Identar manteniendo selección" })

-- Recargar configuración con notificación visual
vim.keymap.set("n", "<leader>rk", function()
	dofile(vim.fn.expand("~/.config/nvim/lua/nahtao97/keymaps.lua"))
	vim.notify("✨ Keymaps recargados correctamente", vim.log.levels.INFO, { title = "Neovim" })
end, { desc = "Recargar Keymaps" })

vim.keymap.set("n", "<leader>rc", function()
	dofile(vim.env.MYVIMRC or vim.fn.expand("~/.config/nvim/init.lua"))
	vim.notify("🚀 Configuración completa recargada", vim.log.levels.INFO, { title = "Neovim" })
end, { desc = "Recargar toda la configuración" })




