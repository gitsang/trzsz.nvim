local M = {}

---@class TrzszOptions
---@field width? integer
---@field trz_cmd? string

---Setup function for trzsz.nvim
---@param opts? TrzszOptions
function M.setup(opts)
	opts = opts or {}
	local width = opts.width or 80
	local trz_cmd = opts.trz_cmd or "trz"

	-- Create Trz command
	vim.api.nvim_create_user_command("Trz", function()
		-- Create a vertical split
		vim.cmd("vsplit")
		local win = vim.api.nvim_get_current_win()

		-- Set window width and fix it
		vim.api.nvim_win_set_width(win, width)
		vim.api.nvim_set_option_value("winfixwidth", true, { win = win })

		-- Open terminal and run trz command
		vim.cmd("terminal " .. trz_cmd)

		-- Set buffer options to hide from buffer tab
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_set_option_value("buflisted", false, { buf = buf })

		-- Set up terminal key mappings for window navigation
		local term_opts = { buffer = buf, silent = true }
		vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", term_opts)
		vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", term_opts)
		vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", term_opts)
		vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", term_opts)

		-- Set up autocmd to enter terminal mode when entering trz terminal window
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
	end, {})

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
						-- Check if this is a trz terminal (not listed in buffer list)
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
