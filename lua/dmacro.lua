local dmacro_key = nil

local function guess_macro_1()
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

local function guess_macro_2()
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

local function record_macro(_, typed)
	if typed ~= "" and typed ~= nil then
		vim.b.dmacro_history = vim.fn.extend({ typed }, vim.b.dmacro_history or {})
		if string.upper(vim.fn.keytrans(typed)) ~= string.upper(dmacro_key) then
			if vim.b.dmacro_prev_macro then
				vim.b.dmacro_prev_macro = nil
				vim.b.dmacro_history = {}
			end
		end
	end
end

local function play_macro()
	vim.b.dmacro_history = vim.list_slice(vim.b.dmacro_history or {}, 2)
	local macro = vim.b.dmacro_prev_macro
	macro = macro or guess_macro_1()
	if macro then
		vim.fn.feedkeys(table.concat(vim.fn.reverse(macro)))
		vim.b.dmacro_history = vim.fn.extend(macro, vim.b.dmacro_history)
		vim.b.dmacro_prev_macro = macro
		return
	end
	macro = macro or guess_macro_2()
	if macro then
		vim.fn.feedkeys(table.concat(vim.fn.reverse(macro)))
		vim.b.dmacro_history = vim.fn.extend(macro, vim.b.dmacro_history)
		vim.b.dmacro_prev_macro = nil
		return
	end
end

local function setup(opts)
	opts = opts or {}
	dmacro_key = opts.dmacro_key
	if not dmacro_key then
		print('dmacro_key is undefined')
	end
	vim.on_key(record_macro)
	vim.keymap.set({ "i", "n" }, dmacro_key, play_macro)
end

return { setup = setup }
