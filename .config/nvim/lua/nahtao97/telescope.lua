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

local function get_indent(str)
	local s = str:match("^(%s*)")
	return s and #s or 0
end

local function build_collapsed_preview(filename, target_line)
	local ok, raw_lines = pcall(vim.fn.readfile, filename)
	if not ok or not raw_lines or #raw_lines == 0 then
		return {}, 1
	end
	target_line = math.max(1, math.min(target_line, #raw_lines))

	local ancestors = {}
	local cur_idx = target_line
	local cur_indent = get_indent(raw_lines[cur_idx])

	while cur_idx > 1 and cur_indent > 0 do
		cur_idx = cur_idx - 1
		local line_str = raw_lines[cur_idx]
		if line_str:match("%S") and not line_str:match("^%s*#") then
			local indent = get_indent(line_str)
			if indent < cur_indent then
				table.insert(ancestors, 1, cur_idx)
				cur_indent = indent
			end
		end
	end

	local milestones = {}
	for _, a in ipairs(ancestors) do
		table.insert(milestones, a)
	end
	table.insert(milestones, target_line)
	if target_line + 1 <= #raw_lines then
		table.insert(milestones, target_line + 1)
	end
	if target_line + 2 <= #raw_lines then
		table.insert(milestones, target_line + 2)
	end

	local display_lines = {}
	local target_display_idx = 1
	local max_gap = 3

	for m_idx = 1, #milestones do
		local cur_line_num = milestones[m_idx]
		local prev_line_num = milestones[m_idx - 1]

		if prev_line_num then
			local gap = cur_line_num - prev_line_num - 1
			if gap > max_gap then
				local indent_str = string.rep(" ", get_indent(raw_lines[cur_line_num]))
				table.insert(display_lines, indent_str .. "... (" .. gap .. " lineas omitidas)")
			elseif gap > 0 then
				for g = prev_line_num + 1, cur_line_num - 1 do
					table.insert(display_lines, raw_lines[g])
				end
			end
		end

		table.insert(display_lines, raw_lines[cur_line_num])
		if cur_line_num == target_line then
			target_display_idx = #display_lines
		end
	end

	return display_lines, target_display_idx
end

local function yq_search(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or uv.cwd()

	if vim.fn.executable("yq") == 0 then
		vim.notify("yq no está instalado en el sistema. Asegúrate de tener mikefarah/yq instalado.", vim.log.levels.ERROR, { title = "YAML Query" })
		return
	end

	local current_prompt = ""
	local ns_preview_hl = vim.api.nvim_create_namespace("yq_preview_hl")
	local previewers = require("telescope.previewers")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local bash_script = [[
		QUERY="$1"
		QUERY="${QUERY#yq }"
		QUERY="${QUERY#: }"
		QUERY_SPACES="${QUERY//[.\/,]/ }"
		read -ra RAW_KEYS <<< "$QUERY_SPACES"
		KEYS=()
		for k in "${RAW_KEYS[@]}"; do
			k="$(echo "$k" | xargs)"
			[ -n "$k" ] && KEYS+=("$k")
		done

		[ ${#KEYS[@]} -eq 0 ] && exit 0

		CANDIDATE_FILES=""
		if command -v rg >/dev/null 2>&1; then
			FIRST_KEY="${KEYS[0]}"
			CANDIDATE_FILES=$(rg -l -g "*.yaml" -g "*.yml" --glob "!*.tpl" -i "^\s*[\"']?${FIRST_KEY}[\"']?\s*:" 2>/dev/null)
			if [ -z "$CANDIDATE_FILES" ]; then
				CANDIDATE_FILES=$(rg -l -g "*.yaml" -g "*.yml" --glob "!*.tpl" -i -- "$FIRST_KEY" 2>/dev/null)
			fi

			for (( i=1; i<${#KEYS[@]}; i++ )); do
				[ -z "$CANDIDATE_FILES" ] && break
				k="${KEYS[i]}"
				NEXT_FILES=$(printf "%s\n" "$CANDIDATE_FILES" | xargs -r rg -l -i "^\s*[\"']?${k}[\"']?\s*:" 2>/dev/null)
				if [ -z "$NEXT_FILES" ]; then
					NEXT_FILES=$(printf "%s\n" "$CANDIDATE_FILES" | xargs -r rg -l -i -- "$k" 2>/dev/null)
				fi
				CANDIDATE_FILES="$NEXT_FILES"
			done
		fi

		if [ -z "$CANDIDATE_FILES" ]; then
			CANDIDATE_FILES=$(find . -maxdepth 6 -type f \( -name "*.yaml" -o -name "*.yml" \) ! -name "*.tpl" 2>/dev/null | head -n 500)
		fi

		[ -z "$CANDIDATE_FILES" ] && exit 0

		PATH_EXPR=""
		for k in "${KEYS[@]}"; do
			[ -n "$k" ] && PATH_EXPR="${PATH_EXPR}.[\"${k}\"]? | "
		done

		EXPR=".. | ${PATH_EXPR}select(. != null) | [filename, (line // 1), 1, (to_json(0) | trim)] | join(\":\")"

		printf "%s\n" "$CANDIDATE_FILES" | head -n 200 | xargs -r -P 4 -n 1 yq -N -r "$EXPR" 2>/dev/null | grep --line-buffered -E '^.+:[0-9]+:'
	]]

	local custom_entry_maker = function(line)
		if not line or line == "" or line:match("^%s*$") or line:match("^%-%-%-") then
			return nil
		end

		local filename, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
		if not filename then
			filename, lnum, text = line:match("^(.-):(%d+):(.*)$")
			col = 1
		end

		if not filename or not lnum then
			return nil
		end

		lnum = tonumber(lnum) or 1
		col = tonumber(col) or 1
		filename = filename:gsub("^%./", "")
		text = text or ""

		local clean_val = tostring(text)
		if clean_val:sub(1, 1) == '"' and clean_val:sub(-1, -1) == '"' and #clean_val >= 2 then
			clean_val = clean_val:sub(2, -2)
		end

		local display_val = clean_val
		if #display_val > 30 then
			display_val = display_val:sub(1, 27) .. "..."
		end

		local display_text = string.format("%-30s │ %s:%d", display_val, filename, lnum)
		local abs_path = vim.fs.normalize(vim.startswith(filename, "/") and filename or (opts.cwd .. "/" .. filename))

		return {
			value = line,
			display = display_text,
			ordinal = string.format("%s %s", clean_val, filename),
			filename = filename,
			path = abs_path,
			lnum = lnum,
			col = col,
			text = clean_val,
		}
	end

	local yq_previewer = previewers.new_buffer_previewer({
		title = "YAML Context Preview",
		dyn_title = function(_, entry)
			return entry.filename or "Preview"
		end,
		define_preview = function(self, entry, status)
			if not entry or not entry.filename then
				return
			end

			local active_prompt = current_prompt
			if status and status.picker then
				local p = status.picker:_get_prompt()
				if p and p ~= "" then
					active_prompt = p
				end
			end

			local clean_query = (active_prompt or ""):gsub("^yq%s+", "")
			local query_keys = {}
			for k in clean_query:gmatch("[^%.%s]+") do
				if #k > 0 then
					table.insert(query_keys, k)
				end
			end

			local full_path = entry.path or vim.fn.expand(entry.filename)
			local display_lines, target_disp_idx = build_collapsed_preview(full_path, entry.lnum or 1)

			vim.bo[self.state.bufnr].modifiable = true
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, display_lines)
			vim.bo[self.state.bufnr].modifiable = false
			vim.bo[self.state.bufnr].filetype = "yaml"

			-- Center on target line in preview window
			if self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
				pcall(vim.api.nvim_win_set_cursor, self.state.winid, { target_disp_idx, 0 })
				pcall(function()
					vim.api.nvim_win_call(self.state.winid, function()
						vim.cmd("norm! zz")
					end)
				end)
			end

			-- Apply highlights
			pcall(vim.api.nvim_buf_clear_namespace, self.state.bufnr, ns_preview_hl, 0, -1)

			-- Background highlight for the target line
			if target_disp_idx and target_disp_idx <= #display_lines then
				pcall(vim.api.nvim_buf_add_highlight, self.state.bufnr, ns_preview_hl, "TelescopePreviewLine", target_disp_idx - 1, 0, -1)
			end

			-- Highlight matched keys and ellipses
			for line_idx, line_text in ipairs(display_lines) do
				if line_text:match("%.%.%.") then
					pcall(vim.api.nvim_buf_add_highlight, self.state.bufnr, ns_preview_hl, "Comment", line_idx - 1, 0, -1)
				end

				local lower_line = line_text:lower()
				for _, key in ipairs(query_keys) do
					local lower_key = key:lower()
					local start_col = 0
					while true do
						local s, e = lower_line:find(lower_key, start_col + 1, true)
						if not s then
							break
						end
						pcall(vim.api.nvim_buf_add_highlight, self.state.bufnr, ns_preview_hl, "TelescopePreviewMatch", line_idx - 1, s - 1, e)
						start_col = e
					end
				end
			end
		end,
	})

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" or #prompt < 2 then
				return nil
			end
			current_prompt = prompt
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
			previewer = yq_previewer,
			sorter = require("telescope.sorters").empty(),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()
					if not entry then
						vim.notify("No hay ninguna coincidencia seleccionada.", vim.log.levels.WARN, { title = "YAML Query" })
						return
					end
					actions.close(prompt_bufnr)
					local target_path = entry.path or entry.filename
					if target_path and target_path ~= "" then
						vim.cmd("edit " .. vim.fn.fnameescape(target_path))
						if entry.lnum then
							local max_line = vim.api.nvim_buf_line_count(0)
							local target_row = math.max(1, math.min(entry.lnum, max_line))
							local target_col = math.max(0, (entry.col or 1) - 1)
							pcall(vim.api.nvim_win_set_cursor, 0, { target_row, target_col })
							vim.cmd("norm! zz")
						end
					end
				end)
				return true
			end,
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
