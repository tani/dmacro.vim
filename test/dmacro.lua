local dmacro = require('./lua/dmacro')

--- @param name string
--- @param func fun()
local function test(name, func)
  print('Test: ' .. name .. ' started')
  func()
  print('Test: ' .. name .. ' passed')
end

test('guess_macro_1:ok', function()
  local keys = { 'd', 'c', 'b', 'a', 'c', 'b', 'a' }
  local expected = { 5, 7 } -- { 'c', 'b', 'a' }
  local actual = dmacro.guess_macro_1(keys)
  assert(vim.deep_equal(expected, actual))
end)

test('guess_macro_1:ng', function()
  local keys = { 'd', 'c', 'b', 'a', 'c', 'b' }
  local expected = nil
  local actual = dmacro.guess_macro_1(keys)
  assert(vim.deep_equal(expected, actual))
end)

test('guess_macro_2:ok', function()
  local keys = { 'd', 'c', 'b', 'a', 'c', 'b' }
  local expected = { 4, 4 } -- { 'a' }
  local actual = dmacro.guess_macro_2(keys)
  assert(vim.deep_equal(expected, actual))
end)

test('is_macro_still_valid:ok', function ()
  local keys = { 'd', 'c', 'b', 'a', 'c', 'b', 'a' }
  local macro = { 2, 4 }
  assert(dmacro.has_prev_macro_suffix(macro, keys))
end)

test('is_macro_still_valid:ng', function ()
  local keys = { 'd', 'c', 'b', 'a', 'c', 'b', 'a' }
  local macro = { 2, 3 }
  assert(not dmacro.has_prev_macro_suffix(macro, keys))
end)

test('get_and_set_state', function()
  local keys = { 'a', 'b', 'c', 'a', 'b', 'c', 'd' }
  local macro = { 1, 1 }
  local expected_keys = keys
  local expected_macro = macro
  dmacro.set_state(keys, macro)
  local actual_keys, actual_macro = dmacro.get_state()
  assert(expected_keys == actual_keys)
  assert(expected_macro == actual_macro)
end)

test('span_equal', function()
  local keys = { 'd', 'c', 'b', 'a', 'c', 'b', 'a' }
  assert(dmacro.span_equal(keys, 2, 5, 3))
  assert(not dmacro.span_equal(keys, 1, 5, 3))
end)
