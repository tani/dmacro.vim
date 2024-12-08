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

--- Guess the macro from the keys.
--- keys: { old --> new }, find the repeated pattern: { ..., <pattern>, <pattern> }
--- @param keys string[]: A table of keys to guess the macro from.
--- @return string[]? macro: A table representing the guessed macro, or nil if no macro could be guessed.
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
      return vim.list_slice(keys, pat_start, keys_len)
      -- (1) vim.list_slice(keys, 5, 7) = { 'c', 'b', 'a' }
    end
  end
  return nil
end

--- Guess the macro from the keys.
--- keys: { old --> new }, find the completion between repeated pattern: { ..., <pattern>, <completion>, <pattern> }
--- @param keys string[]: A table of keys to guess the macro from.
--- @return string[]? macro: A table representing the guessed macro, or nil if no macro could be guessed.
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
        return vim.list_slice(keys, cmp_start, cmp_finish)
        -- (2 - 2) vim.list_slice(keys, 4, 4) = { 'a' }
      end
    end
  end
  return nil
end

do
  --- @type table<integer, { keys: string[]?, macro: string[]? }>
  local buf_states = {}
  vim.api.nvim_create_autocmd('BufDelete', {
    group = vim.api.nvim_create_augroup('Dmacro', { clear = true }),
    callback = function(cx)
      buf_states[cx.buf] = nil
    end,
  })

  --- Set the current state of dmacro.
  -- This function sets the current keys and previous macro of dmacro in the buffer.
  --- @param keys string[]?: The keys you have typed.
  --- @param macro string[]?: The previous macro to be set.
  function _M.set_state(keys, macro)
    buf_states[vim.api.nvim_get_current_buf()] = { keys = keys, macro = macro }
  end

  --- Get the current state of dmacro.
  -- This function retrieves the current keys and previous macro of dmacro from the buffer.
  --- @return string[]? keys: The keys you have typed.
  --- @return string[]? macro: The previous macro to be set.
  function _M.get_state()
    local state = buf_states[vim.api.nvim_get_current_buf()]
    if state then
      return state.keys, state.macro
    end
  end
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
    table.remove(keys)
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
