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

	-- Helper function to create floating terminal
	local function create_float_terminal(cmd, title)
		local ui = vim.api.nvim_list_uis()[1]
		local win_width = math.floor(ui.width * 0.8)
		local win_height = math.floor(ui.height * 0.8)

		local buf = vim.api.nvim_create_buf(false, true)
		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = win_width,
			height = win_height,
			col = math.floor((ui.width - win_width) / 2),
			row = math.floor((ui.height - win_height) / 2),
			border = "rounded",
			title = " " .. title .. " ",
			title_pos = "center",
			style = "minimal",
		})

		-- Set buffer options
		vim.api.nvim_buf_set_option(buf, "buftype", "terminal")
		vim.api.nvim_buf_set_option(buf, "buflisted", false)

		-- Start terminal
		local term_id = vim.fn.termopen(cmd, {
			on_exit = function(_, exit_code, _)
				vim.api.nvim_win_close(win, true)
				if exit_code == 0 then
					vim.notify(title .. " completed successfully", vim.log.levels.INFO)
				else
					vim.notify(title .. " failed with exit code: " .. exit_code, vim.log.levels.ERROR)
				end
			end,
		})

		-- Enter terminal mode
		vim.cmd("startinsert")

		return { buf = buf, win = win, term_id = term_id }
	end

	-- Create Trz command
	vim.api.nvim_create_user_command("Trz", function()
		local terminal = create_float_terminal(trz_cmd, "trz - Upload Files")

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
		create_float_terminal(cmd, "tsz - Download Files")
	end, {
		nargs = "*",
		complete = "file",
	})
end

return M