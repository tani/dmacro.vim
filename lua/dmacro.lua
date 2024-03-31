local function guess_completion_1()
	local hist = vim.b.dmacro_history
	for i = math.floor(#hist / 2), 1, -1 do
		local span = vim.list_slice(hist, 1, i)
		local spanspan = vim.fn.extend(span, span)
		local double = vim.list_slice(hist, 1, i * 2)
		if vim.deep_equal(double, spanspan) then
			return span
		end
	end
	return nil
end

local function guess_completion_2()
	local hist = vim.b.dmacro_history
	for i = math.floor(#hist / 2), 1, -1 do
		local span = vim.list_slice(hist, 1, i)
		for j = #span, #hist - #span do
			local prevspan = vim.list_slice(hist, j + 1, j + #span)
			if vim.deep_equal(prevspan, span) then
				return vim.list_slice(hist, #span + 1, j)
			end
		end
	end
	return nil
end

local function setup(opts)
	opts = opts or {}
	local dmacro_key = opts.dmacro_key or "<leader>."
	local this_group = vim.api.nvim_create_augroup("dmacro", {})
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = this_group,
		callback = function()
			vim.b.dmacro_history = {}
			vim.b.prev_completion = nil
		end,
	})
	vim.on_key(function(key, typed)
		if typed ~= "" and typed ~= nil then
			vim.b.dmacro_history = vim.fn.extend({ typed }, vim.b.dmacro_history)
			if vim.fn.keytrans(typed) ~= string.upper(dmacro_key) then
				if vim.b.prev_completion then
					vim.b.prev_completion = nil
					vim.b.dmacro_history = {}
				end
			end
		end
	end)
	vim.keymap.set({ "i", "n" }, dmacro_key, function()
		vim.b.dmacro_history = vim.list_slice(vim.b.dmacro_history, 2)
		local completion = vim.b.prev_completion
		completion = completion or guess_completion_1()
		if completion then
			vim.fn.feedkeys(table.concat(vim.fn.reverse(completion)))
			vim.b.dmacro_history = vim.fn.extend(completion, vim.b.dmacro_history)
			vim.b.prev_completion = completion
			return
		end
		completion = completion or guess_completion_2()
		if completion then
			vim.fn.feedkeys(table.concat(vim.fn.reverse(completion)))
			vim.b.dmacro_history = vim.fn.extend(completion, vim.b.dmacro_history)
			vim.b.prev_completion = nil
			return
		end
	end)
end
return { setup = setup }
