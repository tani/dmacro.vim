--- @class dmacro
local _M = {}

--- Compare whether two spans within a given list are equal.
--- @param list any[]: The list containing the spans.
--- @param start1 integer: A start index of the first span.
--- @param start2 integer: A start index of the second span.
--- @param len integer: The length of the spans to compare.
--- @return boolean: `true` if the spans are equal.
function _M.span_equal(list, start1, start2, len)
  for i = 0, len - 1 do
    if list[start1 + i] ~= list[start2 + i] then
      return false
    end
  end
  return true
end

--- A type that represents an inclusive range.
--- @class dmacro.Range
--- @field [1] integer: Start index
--- @field [2] integer: Final index

--- Guess the macro from the keys.
--- keys: { old --> new }, find the repeated pattern: { ..., <pattern>, <pattern> }
--- @param keys string[]: A table of keys to guess the macro from.
--- @return dmacro.Range? macro: A range pointing to the guessed macro, or nil if no macro could be guessed.
function _M.guess_macro_1(keys)
  -- keys = { 'd', 'c', 'b', 'a', 'c', 'b', 'a' }
  local keys_len = #keys -- 7
  for pat_start = math.ceil(keys_len / 2) + 1, keys_len do
    -- (1) pat_start = math.ceil(#keys / 2) + 1 = 5
    local pat_len = keys_len - pat_start + 1
    -- (1) pat_len = 3
    local prevpat_start = pat_start - pat_len
    -- (1) prevpat_start = 2
    if _M.span_equal(keys, prevpat_start, pat_start, pat_len) then
      -- (1) keys[2] == keys[5] and ... and keys[4] == keys[7] = true
      return { pat_start, keys_len } --- @type dmacro.Range
      -- (1) { keys[5], ..., keys[7] } = { 'c', 'b', 'a' }
    end
  end
  return nil
end

--- Guess the macro from the keys.
--- keys: { old --> new }, find the completion between repeated pattern: { ..., <pattern>, <completion>, <pattern> }
--- @param keys string[]: A table of keys to guess the macro from.
--- @return dmacro.Range? macro: A range pointing to the guessed macro, or nil if no macro could be guessed.
function _M.guess_macro_2(keys)
  -- keys = { 'd', 'c', 'b', 'a', 'c', 'b' }
  local keys_len = #keys -- 6
  for pat_start = math.ceil(keys_len / 2) + 1, keys_len do
    -- (1) pat_start = math.ceil(#keys / 2) + 1 = 4
    -- (2) pat_start = 5
    local cmp_finish = pat_start - 1
    -- (1) cmp_finish = 3
    -- (2) cmp_finish = 4
    local pat_len = keys_len - cmp_finish
    -- (1) pat_len = 3
    -- (2) pat_len = 2
    for cmp_start = cmp_finish, pat_len + 1, -1 do
      -- (2 - 1) cmp_start = 4
      -- (2 - 2) cmp_start = 3
      local prevpat_start = cmp_start - pat_len
      -- (2 - 1) prevpat_start = 2
      -- (2 - 2) prevpat_start = 1
      if _M.span_equal(keys, prevpat_start, pat_start, pat_len) then
        -- (2 - 2) keys[2] == keys[5] and keys[3] == keys[6] = true
        return { cmp_start, cmp_finish } --- @type dmacro.Range
        -- (2 - 2) { keys[4] } = { 'a' }
      end
    end
  end
  return nil
end

do
  ---@type string[]?
  local dmacro_keys = nil
  ---@type dmacro.Range?
  local dmacro_macro = nil

  --- Set the current state of dmacro.
  -- This function sets the current keys and previous macro of dmacro in the buffer.
  --- @param keys string[]?: The keys you have typed.
  --- @param macro dmacro.Range?: A range pointing to the previous macro to be set.
  function _M.set_state(keys, macro)
    dmacro_keys, dmacro_macro = keys, macro
  end

  --- Get the current state of dmacro.
  -- This function retrieves the current keys and previous macro of dmacro from the buffer.
  --- @return string[]? keys: The keys you have typed.
  --- @return dmacro.Range? macro: A range pointing to the previous macro to be set.
  function _M.get_state()
    return dmacro_keys, dmacro_macro
  end
end

--- This function is responsible for handling the dynamic macro functionality in Neovim.
-- It first retrieves the current state and then removes the last key typed.
-- If a macro is not already defined, it attempts to guess the macro using the `guess_macro_1` function.
-- If a macro is found or guessed, it is then fed to Neovim's input.
-- If no macro was found in the first guess, it attempts to guess the macro again using the `guess_macro_2` function.
-- If a macro is found in the second guess, it is fed to Neovim's input.
-- Finally, the state is updated with the current keys and the found or guessed macro.
function _M.play_macro()
  local keys, macro = _M.get_state()
  if keys then
    table.remove(keys)
    macro = macro or _M.guess_macro_1(keys)
    if macro then
      vim.fn.feedkeys(table.concat(keys, nil, macro[1], macro[2]))
      _M.set_state(vim.list_extend(keys, keys, macro[1], macro[2]), macro)
      return
    end
    macro = macro or _M.guess_macro_2(keys)
    if macro then
      vim.fn.feedkeys(table.concat(keys, nil, macro[1], macro[2]))
      _M.set_state(vim.list_extend(keys, keys, macro[1], macro[2]), nil)
      return
    end
    _M.set_state(keys, macro)
  end
end

--- Checks if the `keys` has a suffix that matches the previously used macro.
--- @param macro dmacro.Range
--- @param keys string[]
--- @return boolean
function _M.has_prev_macro_suffix(macro, keys)
  local macro_start = macro[1]
  local macro_len = macro[2] - macro[1] + 1
  local suffix_start = #keys - macro_len + 1
  return _M.span_equal(keys, macro_start, suffix_start, macro_len)
end

--- Records a macro.
-- This function records a macro based on the typed keys. It first checks if the typed keys are not empty or nil.
-- Then it retrieves the current state of the keys and the range pointing to a macro. If the macro is not valid,
-- it resets the keys and the range to nil.
-- Finally, it sets the state with the extended list of keys (or an empty list if keys is nil) and the macro.
--- @param _ any: Unused parameter
--- @param typed string: The keys typed by the user
function _M.record_macro(_, typed)
  if typed ~= '' and typed ~= nil then
    local keys, macro = _M.get_state()
    if keys and macro and not _M.has_prev_macro_suffix(macro, keys) then
      keys, macro = nil, nil
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
