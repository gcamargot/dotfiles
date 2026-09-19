local telescope_ok, telescope = pcall(require, "telescope")
if not telescope_ok then
	return
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local uv = vim.uv or vim.loop

local function live_multigrep(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or uv.cwd()

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" then
				return
			end
			local parts = vim.split(prompt, "  ")
			local args = { "rg" }
			if parts[1] then
				-- e?
				table.insert(args, "-e")
				table.insert(args, parts[1])
			end

			if parts[2] then
				-- glob
				table.insert(args, "-g")
				table.insert(args, parts[2])
			end

			return vim.tbl_flatten({
				args,
				{ "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
			})
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})

	pickers
		.new(opts, {
			debounce = 100,
			prompt_title = "multi grep",
			finder = finder,
			previewer = conf.grep_previewer(opts),
			sorter = require("telescope.sorters").empty(),
		})
		:find()
end

telescope.setup({
	defaults = {
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
	},
})
--telescope.load_extension("projects")

local function yq_search(initial_query)
	if vim.fn.executable("yq") == 0 then
		vim.notify("yq no está instalado en el sistema. Asegúrate de tener mikefarah/yq instalado.", vim.log.levels.ERROR, { title = "YAML Query" })
		return
	end

	local function run_search(query_str)
		if not query_str or query_str:match("^%s*$") then
			return
		end

		local clean_input = query_str:gsub("^yq%s+", ""):gsub("^%s+", ""):gsub("%s+$", "")
		if clean_input == "" then
			return
		end

		-- Buscar archivos YAML en el directorio actual
		local files = {}
		if vim.fn.executable("rg") == 1 then
			files = vim.fn.systemlist("rg --files -g '*.yaml' -g '*.yml' 2>/dev/null")
		end
		if #files == 0 then
			files = vim.fn.systemlist("find . -type f \\( -name '*.yaml' -o -name '*.yml' \\) 2>/dev/null")
		end

		if #files == 0 then
			vim.notify("No se encontraron archivos YAML (.yaml / .yml) en este directorio.", vim.log.levels.WARN, { title = "YAML Query" })
			return
		end

		-- Construir filtro de yq
		local yq_filter
		if clean_input:find("[|%[%]]") then
			yq_filter = string.format("select(%s != null) | [filename, (line // 1), (%s | to_json(0) | trim)] | join(\"\\t\")", clean_input, clean_input)
		else
			local keys = {}
			for key in clean_input:gmatch("[^%.]+") do
				table.insert(keys, key)
			end
			local path_expr = ""
			for _, k in ipairs(keys) do
				path_expr = path_expr .. string.format('.["%s"]?', k)
			end
			yq_filter = string.format('.. | %s | select(. != null) | [filename, (line // 1), (to_json(0) | trim)] | join("\\t")', path_expr)
		end

		-- Ejecutar yq por lotes
		local results = {}
		local batch_size = 100
		for i = 1, #files, batch_size do
			local batch = { "yq", "-N", "-r", yq_filter }
			for j = i, math.min(i + batch_size - 1, #files) do
				table.insert(batch, files[j])
			end
			local out = vim.fn.systemlist(batch)
			for _, line in ipairs(out) do
				if line and line ~= "" and not line:match("^%-%-%-") then
					table.insert(results, line)
				end
			end
		end

		local parsed_entries = {}
		for _, line in ipairs(results) do
			local parts = vim.split(line, "\t")
			if #parts >= 3 then
				local filename = parts[1]:gsub("^%./", "")
				local lnum = tonumber(parts[2]) or 1
				local val = table.concat(parts, "\t", 3)
				if val:sub(1, 1) == '"' and val:sub(-1, -1) == '"' and #val >= 2 then
					val = val:sub(2, -2)
				end
				table.insert(parsed_entries, {
					filename = filename,
					lnum = lnum,
					val = val,
				})
			end
		end

		if #parsed_entries == 0 then
			vim.notify("No se encontraron coincidencias para: " .. clean_input, vim.log.levels.INFO, { title = "YAML Query" })
			return
		end

		pickers.new({}, {
			prompt_title = "yq: " .. clean_input,
			finder = finders.new_table({
				results = parsed_entries,
				entry_maker = function(entry)
					local display_val = tostring(entry.val or "")
					if #display_val > 28 then
						display_val = display_val:sub(1, 25) .. "..."
					end
					local display_text = string.format("%-28s │ %s:%d", display_val, entry.filename, entry.lnum)
					return {
						value = entry,
						display = display_text,
						ordinal = string.format("%s %s", entry.val, entry.filename),
						filename = entry.filename,
						lnum = entry.lnum,
						col = 1,
					}
				end,
			}),
			previewer = conf.grep_previewer({}),
			sorter = conf.generic_sorter({}),
		}):find()
	end

	if initial_query and initial_query ~= "" then
		run_search(initial_query)
	else
		vim.ui.input({
			prompt = "YAML Query (yq): ",
			default = "",
		}, function(input)
			run_search(input)
		end)
	end
end

local M = {
	live_multigrep = live_multigrep,
	yq_search = yq_search,
}

vim.api.nvim_create_user_command("YqSearch", function(opts)
	yq_search(opts.args)
end, { nargs = "?" })

return M
