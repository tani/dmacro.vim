--- @class dmacro
local _M = {}

--- Guess the macro from the keys.
--- keys: { old --> new }, find the repeated pattern: { ..., <pattern>, <pattern> }
--- @param keys string[]: A table of keys to guess the macro from.
--- @return string[]? macro: A table representing the guessed macro, or nil if no macro could be guessed.
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
--- @param keys string[]: A table of keys to guess the macro from.
--- @return string[]? macro: A table representing the guessed macro, or nil if no macro could be guessed.
function _M.guess_macro_2(keys)
  -- keys = { 'd', 'c', 'b', 'a', 'c', 'b' }, #keys = 6
  for i = math.ceil(#keys / 2), #keys do
    -- (1) i = math.ceil(#keys / 2) = 3
    -- (2) i = 4
    local span = vim.list_slice(keys, i + 1, #keys)
    -- (1) span = { 'a', 'c', 'b' }
    -- (2) span = { 'c', 'b' }
    for j = i, #span, -1 do
      -- (1 - 1) j = 3
      -- (2 - 1) j = 4
      -- (2 - 2) j = 3
      local prevspan = vim.list_slice(keys, j - #span + 1, j)
      -- (1 - 1) prevspan = vim.list_slice(keys, 3 - 3 + 1 = 1, 3) = { 'd', 'c', 'b' }
      -- (2 - 1) prevspan = vim.list_slice(keys, 4 - 2 + 1 = 3, 4) = { 'b', 'a' }
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
--- @param keys string[]?: The keys you have typed.
--- @param macro string[]?: The previous macro to be set.
function _M.set_state(keys, macro)
  vim.b.dmacro_keys = keys
  vim.b.dmacro_macro = macro
end

--- Get the current state of dmacro.
-- This function retrieves the current keys and previous macro of dmacro from the buffer.
--- @return string[]? keys: The keys you have typed.
--- @return string[]? macro: The previous macro to be set.
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
function _M.play_macro()
  local keys, macro = _M.get_state()
  if keys then
    keys = vim.list_slice(keys, 1, #keys - 1)
    macro = macro or _M.guess_macro_1(keys)
    if macro then
      vim.fn.feedkeys(table.concat(macro))
      _M.set_state(vim.list_extend(keys, macro), macro)
      return
    end
    macro = macro or _M.guess_macro_2(keys)
    if macro then
      vim.fn.feedkeys(table.concat(macro))
      _M.set_state(vim.list_extend(keys, macro), nil)
      return
    end
    _M.set_state(keys, macro)
  end
end

--- Records a macro.
-- This function records a macro based on the typed keys. It first checks if the typed keys are not empty or nil.
-- Then it retrieves the current state of keys and macro. If the length of keys is greater than or equal to the length of macro,
-- it iterates over the macro and compares each key with the corresponding key in the macro.
-- If a mismatch is found, it resets the keys and macro to nil and breaks the loop.
-- Finally, it sets the state with the extended list of keys (or an empty list if keys is nil) and the macro.
--- @param _ any: Unused parameter
--- @param typed string: The keys typed by the user
function _M.record_macro(_, typed)
  if typed ~= '' and typed ~= nil then
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
    _M.set_state(vim.list_extend(keys or {}, { typed }), macro)
  end
end

--- Setup function for dmacro.
--- @deprecated
function _M.setup(opts)
  vim.notify('dmacro: dmacro.setup() is obsolete, use vim.keymap.set() directly.', vim.log.levels.WARN)
end

return _M
