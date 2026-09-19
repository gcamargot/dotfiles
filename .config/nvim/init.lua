pcall(require, "impatient")

-- Global Helpers
local k_opts = { noremap = true, silent = true }

LUA_KEYMAP = function(mode, key, command, args)
	if args == nil then
		args = ""
	end
	vim.keymap.set(mode, key, "<cmd>lua " .. command .. "(" .. args .. ")<CR>", k_opts)
end

CMD_KEYMAP = function(mode, key, command)
	vim.keymap.set(mode, key, "<cmd>" .. command .. "<CR>", k_opts)
end

require("nahtao97.plugins")
require("nahtao97.options")
require("nahtao97.telescope")
require("nahtao97.statusline")
require("nahtao97.snippets")
require("nahtao97.lsp")
require("nahtao97.keymaps")
