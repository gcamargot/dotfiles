if vim.lsp.config then
	vim.lsp.config["ocamllsp"] = {
		cmd = { "ocamllsp" },
		filetypes = {
			"ocaml",
			"ocaml.interface",
			"ocaml.menhir",
			"ocaml.ocamllex",
			"dune",
			"reason",
		},
		root_markers = {
			{ "dune-project", "dune-workspace" },
			{ "*.opam", "esy.json", "package.json" },
			".git",
		},
		settings = {},
	}
end

local servers = {
	"clangd",
	"rust_analyzer",
	"ts_ls",
	"yamlls",
	"jsonls",
	"gopls",
	"salt_ls",
	"dockerls",
	"bashls",
	"awk_ls",
	"ocamllsp",
	"elixirls",
	-- "ty",
	-- "ruff",
	"basedpyright",
}

if vim.lsp.enable then
	for _, server in pairs(servers) do
		vim.lsp.enable(server)
	end
else
	local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
	if lspconfig_ok then
		for _, server in pairs(servers) do
			if lspconfig[server] then
				lspconfig[server].setup({})
			end
		end
	end
end

pcall(function()
	require("fidget").setup({})
end)
