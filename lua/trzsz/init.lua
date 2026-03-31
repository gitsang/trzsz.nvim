local M = {}

---@class TrzszOptions
---@field height? integer
---@field trz_cmd? string|string[]
---@field tsz_cmd? string|string[]

---Setup function for trzsz.nvim
---@param opts? TrzszOptions
function M.setup(opts)
	opts = opts or {}
	local height = opts.height or 5
	local trz_cmd = opts.trz_cmd or "trz"
	local tsz_cmd = opts.tsz_cmd or "tsz"
	local augroup = vim.api.nvim_create_augroup("trzsz_nvim", { clear = true })

	local function build_command(cmd, extra_args)
		extra_args = extra_args or {}
		local parts = {}

		if type(cmd) == "table" then
			for _, arg in ipairs(cmd) do
				table.insert(parts, vim.fn.shellescape(arg))
			end
		else
			table.insert(parts, cmd)
		end

		for _, arg in ipairs(extra_args) do
			table.insert(parts, vim.fn.shellescape(arg))
		end

		return table.concat(parts, " ")
	end

	local function open_transfer_terminal(cmd)
		vim.cmd("topleft split")
		local win = vim.api.nvim_get_current_win()

		vim.api.nvim_win_set_height(win, height)
		vim.api.nvim_set_option_value("winfixheight", true, { win = win })
		vim.w[win].trzsz_transfer_terminal = true

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

		vim.api.nvim_create_autocmd("WinEnter", {
			group = augroup,
			buffer = buf,
			callback = function()
				if vim.api.nvim_get_current_win() == win then
					vim.cmd("startinsert")
				end
			end,
		})

		-- Enter terminal mode immediately
		vim.cmd("startinsert")
	end

	-- Create Trz command
	vim.api.nvim_create_user_command("Trz", function()
		open_transfer_terminal(build_command(trz_cmd))
	end, {})

	vim.api.nvim_create_user_command("Tsz", function(params)
		local filename = vim.fn.fnamemodify(params.args, ":p")
		if vim.fn.filereadable(filename) ~= 1 then
			vim.notify("Tsz: file not found: " .. params.args, vim.log.levels.ERROR)
			return
		end

		open_transfer_terminal(build_command(tsz_cmd, { filename }))
	end, {
		nargs = 1,
		complete = "file",
	})

	vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
		group = augroup,
		callback = function()
			-- Get all windows
			local wins = vim.api.nvim_list_wins()

			-- If WinResized event, only check the resized windows
			if vim.v.event and vim.v.event.windows then
				wins = vim.v.event.windows or {}
			end

			for _, winid in ipairs(wins) do
				if vim.api.nvim_win_is_valid(winid) then
					if vim.w[winid].trzsz_transfer_terminal then
						if vim.api.nvim_win_get_height(winid) ~= height then
							vim.api.nvim_win_set_height(winid, height)
						end
					end
				end
			end
		end,
	})
end

return M
