-- On macOS, ensure SDKROOT points to a valid SDK (e.g. MacOSX.sdk) if not already set,
-- preventing linker TAPI errors when compiling tree-sitter parsers.
if (vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1) and not vim.env.SDKROOT then
	local candidate_sdks = {
		"/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
		"/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk",
	}
	for _, sdk in ipairs(candidate_sdks) do
		if vim.fn.isdirectory(sdk) == 1 then
			vim.env.SDKROOT = sdk
			break
		end
	end
end

local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
	return
end


configs.setup({
	ensure_installed = {
		"javascript",
		"typescript",
		"python",
		"lua",
		"rust",
		"go",
		"ocaml",
		"elixir",
		"heex",
		"eex",
		"surface",
	},
	sync_install = false,
	auto_install = true,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
})
