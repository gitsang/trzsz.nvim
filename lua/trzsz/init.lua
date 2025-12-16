local M = {}

---@class TrzszOptions
---@field width? integer
---@field trz_cmd? string
---@field tsz_cmd? string
---@field temp_log? string

---Setup function for trzsz.nvim
---@param opts? TrzszOptions
function M.setup(opts)
	opts = opts or {}
	local width = opts.width or 80
	local trz_cmd = opts.trz_cmd or "trz | tee /tmp/trz.log"
	local tsz_cmd = opts.tsz_cmd or "tsz"
	local temp_log = opts.temp_log or "/tmp/trz.log"

	-- Helper function to create sidebar terminal
	local function create_sidebar_terminal(cmd, title)
		-- Create a vertical split
		vim.cmd("vsplit")
		local win = vim.api.nvim_get_current_win()

		-- Set window width and fix it
		vim.api.nvim_win_set_width(win, width)
		vim.api.nvim_set_option_value("winfixwidth", true, { win = win })

		-- Open terminal and run command
		vim.cmd("terminal " .. cmd)

		-- Set buffer options to hide from buffer tab
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_set_option_value("buflisted", false, { buf = buf })

		-- Set up terminal key mappings for window navigation
		local term_opts = { buffer = buf, silent = true }
		vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", term_opts)
		vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", term_opts)
		vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", term_opts)
		vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", term_opts)

		-- Set up autocmd to enter terminal mode when entering terminal window
		vim.api.nvim_create_autocmd("WinEnter", {
			buffer = buf,
			callback = function()
				if vim.api.nvim_get_current_win() == win then
					vim.cmd("startinsert")
				end
			end,
		})

		-- Enter terminal mode immediately
		vim.cmd("startinsert")

		return { buf = buf, win = win }
	end

	-- Create Trz command
	vim.api.nvim_create_user_command("Trz", function()
		local terminal = create_sidebar_terminal(trz_cmd, "trz - Upload Files")

		-- Set up autocmd to detect when trz completes and extract filenames
		vim.api.nvim_create_autocmd("TermClose", {
			buffer = terminal.buf,
			once = true,
			callback = function()
				-- Read the temp log file to extract uploaded filenames
				local log_content = vim.fn.readfile(temp_log)
				local uploaded_files = {}

				for _, line in ipairs(log_content) do
					-- Match lines starting with "- " (file entries)
					local filename = line:match("^%- (.+)$")
					if filename then
						table.insert(uploaded_files, filename)
					end
				end

				-- Insert filenames at current cursor position
				if #uploaded_files > 0 then
					local files_text = table.concat(uploaded_files, "\n")
					vim.api.nvim_put(vim.split(files_text, "\n"), "l", true, true)
					vim.notify("Inserted " .. #uploaded_files .. " uploaded filenames", vim.log.levels.INFO)
				end

				-- Clean up temp log file
				vim.fn.delete(temp_log)
			end,
		})
	end, {})

	-- Create Tsz command with optional file argument
	vim.api.nvim_create_user_command("Tsz", function(opts)
		local files = opts.args
		if files == "" then
			vim.notify("Usage: :Tsz <file1> [file2] ...", vim.log.levels.ERROR)
			return
		end

		local cmd = tsz_cmd .. " " .. files
		create_sidebar_terminal(cmd, "tsz - Download Files")
	end, {
		nargs = "*",
		complete = "file",
	})

	-- Add autocommand to maintain width on window resize
	vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
		callback = function()
			-- Get all windows
			local wins = vim.api.nvim_list_wins()

			-- If WinResized event, only check the resized windows
			if vim.v.event and vim.v.event.windows then
				wins = vim.v.event.windows or {}
			end

			for _, winid in ipairs(wins) do
				if vim.api.nvim_win_is_valid(winid) then
					local buf = vim.api.nvim_win_get_buf(winid)
					if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
						-- Check if this is a trzsz terminal (not listed in buffer list)
						if not vim.api.nvim_get_option_value("buflisted", { buf = buf }) then
							vim.api.nvim_win_set_width(winid, width)
						end
					end
				end
			end
		end,
	})
end

return M

