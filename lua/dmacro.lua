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

--- Detects the key mapped to the dmacro function.
-- This function iterates over all the keymaps in the current mode and returns the key that is mapped to the dmacro function.
-- The comparison is case-insensitive.
-- If no such key is found, an error is thrown.
-- @return The key mapped to the dmacro function.
local function detect_dmacro_key()
	local keymap = vim.api.nvim_get_keymap(vim.api.nvim_get_mode().mode)
	for _, k in ipairs(keymap) do
		if string.upper(k.rhs or "") == string.upper('<Plug>(dmacro)') then
			return k.lhs
		end
	end
	error("dmacro_key not found")
end

--- Splits a sequence of keys into individual parts.
-- This function takes a sequence of keys and splits it into individual parts.
-- Each part is either a single character or a sequence of characters enclosed in '<' and '>'.
-- If a '<' is found but there is no corresponding '>', the rest of the sequence is added as a single part.
-- @param sequence The sequence of keys to split.
-- @return A table containing the individual parts of the sequence.
local function split_keys(sequence)
		local parts = {}
		local i = 1
		while i <= #sequence do
				if sequence:sub(i, i) == '<' then
						local end_pos = sequence:find('>', i)
						if end_pos then
								table.insert(parts, sequence:sub(i, end_pos))
								i = end_pos + 1
						else
								-- If '<' is found but there is no corresponding '>', add it as it is
								table.insert(parts, sequence:sub(i))
								break
						end
				else
						table.insert(parts, sequence:sub(i, i))
						i = i + 1
				end
		end
		return parts
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
		local dmacro_key_size = #(split_keys(detect_dmacro_key()))
		local keys, macro = _M.get_state()
		keys = vim.list_slice(keys, 1, #keys - dmacro_key_size)
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
			local dmacro_key_size = #(split_keys(detect_dmacro_key()))
			local keys, macro = _M.get_state()
			if keys and macro and #keys - (dmacro_key_size - 1) >= #macro then
				for i = 0, #macro - 1 do
					local j = #keys - i - (dmacro_key_size - 1)
					local k = #macro - i
					if keys[j] ~= macro[k] then
						macro = nil
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

return _M
