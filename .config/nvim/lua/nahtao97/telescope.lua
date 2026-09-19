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

local function yq_search(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or uv.cwd()

	if vim.fn.executable("yq") == 0 then
		vim.notify("yq no está instalado en el sistema. Asegúrate de tener mikefarah/yq instalado.", vim.log.levels.ERROR, { title = "YAML Query" })
		return
	end

	local bash_script = [[
		QUERY="$1"
		QUERY="${QUERY#yq }"
		QUERY="$(echo "$QUERY" | xargs)"
		[ -z "$QUERY" ] && exit 0

		IFS="." read -ra KEYS <<< "$QUERY"
		LAST_KEY="${KEYS[-1]}"

		FILES=""
		if command -v rg >/dev/null 2>&1 && [ -n "$LAST_KEY" ]; then
			FILES=$(rg -l -- "$LAST_KEY" -g "*.yaml" -g "*.yml" 2>/dev/null)
		fi
		if [ -z "$FILES" ]; then
			FILES=$(find . -maxdepth 8 -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null)
		fi
		[ -z "$FILES" ] && exit 0

		PATH_EXPR=""
		for k in "${KEYS[@]}"; do
			[ -n "$k" ] && PATH_EXPR="${PATH_EXPR}.[\"${k}\"]? | "
		done

		EXPR=".. | ${PATH_EXPR}select(. != null) | [filename, (line // 1), 1, (to_json(0) | trim)] | join(\":\")"
		echo "$FILES" | xargs yq -N -r "$EXPR" 2>/dev/null
	]]

	local base_maker = make_entry.gen_from_vimgrep(opts)

	local custom_entry_maker = function(line)
		local entry = base_maker(line)
		if not entry then
			return nil
		end

		if entry.filename then
			entry.filename = entry.filename:gsub("^%./", "")
		end

		entry.display = function(e)
			local val = tostring(e.text or "")
			if val:sub(1, 1) == '"' and val:sub(-1, -1) == '"' and #val >= 2 then
				val = val:sub(2, -2)
			end
			if #val > 30 then
				val = val:sub(1, 27) .. "..."
			end
			return string.format("%-30s │ %s:%d", val, e.filename, e.lnum)
		end

		return entry
	end

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" or #prompt < 2 then
				return nil
			end
			return { "bash", "-c", bash_script, "--", prompt }
		end,
		entry_maker = custom_entry_maker,
		cwd = opts.cwd,
	})

	pickers
		.new(opts, {
			debounce = 150,
			prompt_title = "Live YAML Query (yq)",
			finder = finder,
			previewer = conf.grep_previewer(opts),
			sorter = require("telescope.sorters").empty(),
		})
		:find()
end

local M = {
	live_multigrep = live_multigrep,
	yq_search = yq_search,
}

vim.api.nvim_create_user_command("YqSearch", function(cmd_opts)
	local opts = {}
	if cmd_opts.args and cmd_opts.args ~= "" then
		opts.default_text = cmd_opts.args
	end
	yq_search(opts)
end, { nargs = "?" })

return M
