local _M = {}

local function guess_macro_1(keys)
	for i = math.floor(#keys / 2), 1, -1 do
		local span = vim.list_slice(keys, 1, i)
		local spanspan = vim.fn.extend(span, span)
		local double = vim.list_slice(keys, 1, i * 2)
		if vim.deep_equal(double, spanspan) then
			return span
		end
	end
	return nil
end

local function guess_macro_2(keys)
	for i = math.floor(#keys / 2), 1, -1 do
		local span = vim.list_slice(keys, 1, i)
		for j = #span, #keys - #span do
			local prevspan = vim.list_slice(keys, j + 1, j + #span)
			if vim.deep_equal(prevspan, span) then
				return vim.list_slice(keys, #span + 1, j)
			end
		end
	end
	return nil
end

--- Create a macro recorder.
-- This function creates a macro recorder that records typed keys.
-- @param dmacro_key the key that triggers the macro recording. If this key is typed, the macro is not reset.
-- @return a function that takes two parameters: the first one is ignored, the second one is the typed key. This function updates the history and the macro based on the typed key.
function _M.create_macro_recorder(dmacro_key)
	return function(_, typed)
		if typed ~= "" and typed ~= nil then
			local keys, macro = _M.get_state()
			_M.set_state(vim.fn.extend({ typed }, keys or {}), macro)
			if macro and string.upper(vim.fn.keytrans(typed)) ~= string.upper(dmacro_key) then
				_M.set_state({}, nil)
			end
		end
	end
end

--- Play the recorded macro.
-- This function plays the recorded macro if it exists. If not, it tries to guess the macro from the keys.
-- The macro is played in reverse order. The keys and the macro are updated after playing.
-- @param keys the current keys you have typed.
-- @param macro the macro to be played. If nil, the function will try to guess the macro.
-- @return two values: the updated keys and the played macro. If no macro was played, the second return value is nil.
function _M.play_macro(keys, macro)
	macro = macro or guess_macro_1(keys)
	if macro then
		vim.fn.feedkeys(table.concat(vim.fn.reverse(macro)))
		return vim.fn.extend(macro, keys), macro
	end
	macro = macro or guess_macro_2(keys)
	if macro then
		vim.fn.feedkeys(table.concat(vim.fn.reverse(macro)))
		return vim.fn.extend(macro, keys), nil
	end
	return keys, nil
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

--- Setup function for dmacro.
-- This function initializes the dmacro with the provided options.
-- If no options are provided, it uses default values.
-- If the 'dmacro_key' option is not provided, it prints a warning message.
-- It sets up a keymap for the 'dmacro_key' to play the macro.
-- @param opts table containing the options for dmacro. It should have a 'dmacro_key' field.
function _M.setup(opts)
	opts = opts or {}
	if not opts.dmacro_key then
		print('dmacro_key is undefined')
	end
	vim.on_key(_M.create_macro_recorder(opts.dmacro_key))
	vim.keymap.set({ "i", "n" }, opts.dmacro_key, function()
		local keys, macro = _M.get_state()
		keys, macro = _M.play_macro(vim.list_slice(keys, 2), macro)
		_M.set_state(keys, macro)
	end)
end

return _M
