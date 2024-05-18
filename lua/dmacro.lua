local _M = {}

--- Guess the macro from the keys.
--- keys: { old --> new }, find the repeated pattern: { ..., <pattern>, <pattern> }
-- @param keys A table of keys to guess the macro from.
-- @return A table representing the guessed macro, or nil if no macro could be guessed.
function _M.guess_macro_1(keys)
	-- keys = { 'd', 'c', 'b', 'a', 'c', 'b', 'a' }, #keys = 7
	for i = math.ceil(#keys / 2), #keys - 1 do
		-- (1) i = math.ceil(#keys / 2) = 4
		local span1 = vim.list_slice(keys, i + 1, #keys)
		-- (1) span1 =  { 'c', 'b', 'a' }
		local span2 = vim.list_slice(keys, i + 1 - #span1, i)
		-- (1) span2 = { 'c', 'b', 'a' }
		if vim.deep_equal(span1, span2) then
			return span1
		end
	end
	return nil
end

--- Guess the macro from the keys.
--- keys: { old --> new }, find the completion between repeated pattern: { ..., <pattern>, <completion>, <pattern> }
-- @param keys A table of keys to guess the macro from.
-- @return A table representing the guessed macro, or nil if no macro could be guessed.
function _M.guess_macro_2(keys)
	-- keys = { 'd', 'c', 'b', 'a', 'c', 'b' }, #keys = 6
	for i = math.ceil(#keys / 2), #keys do
		-- (1) i = math.ceil(#keys / 2) = 3
		-- (2) i = 4
		local span = vim.list_slice(keys, i + 1, #keys)
		-- (1) span = { 'a', 'c', 'b' }
		-- (2) span = { 'c', 'b' }
		for j = i, #span, -1  do
			-- (1 - 1) j = 3
			-- (2 - 1) j = 4
			-- (2 - 2) j = 3
			local prevspan = vim.list_slice(keys, j - #span + 1, j)
			-- (1 - 1) prevspan = vim.list_slice(keys, 3 - 3 + 1 = 1, 3) = { 'd', 'c', 'b' }
			-- (2 - 1) prevspan = vim.list_slice(keys, 4 - 2 + 1 = 3, 4) = { 'a', 'c' }
			-- (2 - 2) prevspan = vim.list_slice(keys, 3 - 2 + 1 = 2, 3) = { 'c', 'b' }
			if vim.deep_equal(prevspan, span) then
				-- (2 - 2) true
				return vim.list_slice(keys, j + 1, i)
				-- (2 - 2) vim.list_slice(keys, 3 + 1 = 4, 4) = { 'a' }
			end
		end
	end
	return nil
end

--- Set the current state of dmacro.
-- This function sets the current keys and previous macro of dmacro in the buffer.
-- @param keys the keys you have typed.
-- @param macro the previous macro to be set.
function _M.set_state(keys, macro)
	vim.b.dmacro_keys = keys
	vim.b.dmacro_macro = macro
end

--- Get the current state of dmacro.
-- This function retrieves the current keys and previous macro of dmacro from the buffer.
-- @return two values: the current keys you have typed and the previous macro.
function _M.get_state()
	return vim.b.dmacro_keys, vim.b.dmacro_macro
end

--- This function is responsible for handling the dynamic macro functionality in Neovim.
-- It first determines the size of the dynamic macro key and retrieves the current state.
-- The keys are then sliced based on the size of the dynamic macro key.
-- If a macro is not already defined, it attempts to guess the macro using the `guess_macro_1` function.
-- If a macro is found or guessed, it is then fed to Neovim's input and the state is updated.
-- If no macro was found in the first guess, it attempts to guess the macro again using the `guess_macro_2` function.
-- If a macro is found in the second guess, it is fed to Neovim's input and the state is updated (with the macro set to nil).
-- Finally, the state is updated with the current keys and the found or guessed macro.
-- @function _M.dmacro
function _M.dmacro()
		local keys, macro = _M.get_state()
		keys = vim.list_slice(keys, 1, #keys - 1)
		macro = macro or _M.guess_macro_1(keys)
		if macro then
				vim.fn.feedkeys(table.concat(macro))
				_M.set_state(vim.list_extend({ unpack(keys) }, { unpack(macro) }), macro)
				return
		end
		macro = macro or _M.guess_macro_2(keys)
		if macro then
				vim.fn.feedkeys(table.concat(macro))
				_M.set_state(vim.list_extend({ unpack(keys) }, { unpack(macro) }), nil)
				return
		end
		_M.set_state(keys, macro)
end

--- Setup function for dmacro.
-- This function initializes the dmacro with the provided options.
-- If no options are provided, it uses default values.
-- If the 'dmacro_key' option is not provided, it prints a warning message.
-- It sets up a keymap for the 'dmacro_key' to play the macro.
-- @param opts table containing the options for dmacro. It should have a 'dmacro_key' field.
function _M.setup(opts)
	opts = opts or {}
	local ns_id_main = vim.api.nvim_create_namespace('dmacro_main')
	vim.on_key(function(_, typed)
		if typed ~= "" and typed ~= nil then
			local keys, macro = _M.get_state()
			if keys and macro and #keys >= #macro then
				for i = 0, #macro - 1 do
					local j = #keys - i
					local k = #macro - i
					if keys[j] ~= macro[k] then
						keys, macro = nil, nil
						break
					end
				end
			end
			_M.set_state(vim.list_extend({ unpack(keys or {}) }, { typed }), macro)
		end
	end, ns_id_main)
	vim.keymap.set({ "i", "n", "v", "x", "s", "o", "c", "t" }, "<Plug>(dmacro)", _M.dmacro)
	if opts.dmacro_key then
		vim.keymap.set({ "i", "n", "v", "x", "s", "o", "c", "t" }, opts.dmacro_key, "<Plug>(dmacro)")
	end
end

-- Note:
-- 一文字分のdmacro_keyではなく、複数のキー組合せの列をdmacro_key として指定しても、
-- vim.on_keyは、そのキー組み合わせが全て入力されたあとの一度のみに発火する。
-- dmacro_key = "g@" の場合、"g" と "@" の間に vim.on_keyが発火することはない。
-- "g@" が入力されたときに、"g@"が入力されたとして、ひとまとめに関数が実行される。

return _M
